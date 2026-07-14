package controllers

import (
	"be-Baju/config"
	"be-Baju/models"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// GetAllOrders mengambil semua data order, diurutkan dari yang terbaru (CreatedAt descending)
func GetAllOrders(c *gin.Context) {
	var orders []models.Order
	// Preload User, OrderItems, dan Product di dalam OrderItems
	err := config.DB.Order("created_at desc").Preload("User").Preload("OrderItems.Product").Find(&orders).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil orders: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"orders": orders,
	})
}

// UpdateOrderStatus memperbarui status order (Pending, Packing, Shipped, Delivered)
func UpdateOrderStatus(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID order tidak valid"})
		return
	}

	var order models.Order
	if err := config.DB.First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order tidak ditemukan"})
		return
	}

	var input struct {
		Status          string `json:"status" binding:"required"`
		ProofOfDelivery string `json:"proof_of_delivery"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validasi nilai status
	validStatuses := map[string]bool{
		"Pending":   true,
		"Packing":   true,
		"Shipped":   true,
		"Delivered": true,
	}

	if !validStatuses[input.Status] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Status tidak valid. Harus salah satu dari: Pending, Packing, Shipped, Delivered"})
		return
	}

	order.Status = input.Status
	if input.Status == "Delivered" && input.ProofOfDelivery != "" {
		order.ProofOfDelivery = input.ProofOfDelivery
	}

	if err := config.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal memperbarui status order: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Status order berhasil diperbarui",
		"order":   order,
	})
}

// GetCustomerOrders mengambil semua riwayat pesanan milik customer yang sedang login
func GetCustomerOrders(c *gin.Context) {
	firebaseUID, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	uidStr := firebaseUID.(string)

	var user models.User
	if err := config.DB.Where("firebase_uid = ?", uidStr).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}

	var orders []models.Order
	err := config.DB.Where("user_id = ?", user.ID).Order("created_at desc").
		Preload("OrderItems.Product").Find(&orders).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil riwayat pesanan: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"orders": orders,
	})
}

// CreateOrder membuat pesanan baru dari checkout
func CreateOrder(c *gin.Context) {
	firebaseUID, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	uidStr := firebaseUID.(string)

	var user models.User
	if err := config.DB.Where("firebase_uid = ?", uidStr).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}

	var input struct {
		ShippingAddress string `json:"shipping_address" binding:"required"`
		TotalPrice      float64 `json:"total_price" binding:"required"`
		PaymentMethod   string `json:"payment_method"`
		Items           []struct {
			ProductID uint    `json:"product_id" binding:"required"`
			Quantity  int     `json:"quantity" binding:"required"`
			Price     float64 `json:"price" binding:"required"`
			Size      string  `json:"size" binding:"required"`
		} `json:"items" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	paymentMethod := "COD"
	if input.PaymentMethod != "" {
		paymentMethod = input.PaymentMethod
	}

	tx := config.DB.Begin()

	order := models.Order{
		UserID:          user.ID,
		TotalPrice:      input.TotalPrice,
		PaymentMethod:   paymentMethod,
		Status:          "Pending",
		ShippingAddress: input.ShippingAddress,
	}

	if err := tx.Create(&order).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat order: " + err.Error()})
		return
	}

	for _, item := range input.Items {
		orderItem := models.OrderItem{
			OrderID:   order.ID,
			ProductID: item.ProductID,
			Quantity:  item.Quantity,
			SubTotal:  item.Price * float64(item.Quantity),
			Size:      item.Size,
		}
		if err := tx.Create(&orderItem).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat item order: " + err.Error()})
			return
		}

		// Kurangi stok produk berdasarkan ukuran
		if err := tx.Model(&models.ProductSize{}).
			Where("product_id = ? AND size = ?", item.ProductID, item.Size).
			Update("stock", config.DB.Raw("stock - ?", item.Quantity)).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengurangi stok produk: " + err.Error()})
			return
		}
	}

	tx.Commit()

	c.JSON(http.StatusCreated, gin.H{
		"message": "Pesanan berhasil dibuat",
		"order":   order,
	})
}

// GetSalesReport mengambil laporan penjualan admin berdasarkan tanggal
func GetSalesReport(c *gin.Context) {
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	query := config.DB.Model(&models.Order{}).Where("status = ?", "Delivered")

	if startDate != "" && endDate != "" {
		sDate := startDate
		eDate := endDate
		// Jika format hanya YYYY-MM-DD, sesuaikan agar mencakup seluruh hari
		if len(startDate) == 10 {
			sDate = startDate + " 00:00:00"
		}
		if len(endDate) == 10 {
			eDate = endDate + " 23:59:59"
		}
		query = query.Where("created_at BETWEEN ? AND ?", sDate, eDate)
	}

	var orders []models.Order
	err := query.Preload("User").Preload("OrderItems.Product").Find(&orders).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil data laporan penjualan: " + err.Error()})
		return
	}

	var totalRevenue float64 = 0
	for _, order := range orders {
		totalRevenue += order.TotalPrice
	}

	c.JSON(http.StatusOK, gin.H{
		"total_revenue": totalRevenue,
		"total_orders":  len(orders),
		"orders":        orders,
	})
}

