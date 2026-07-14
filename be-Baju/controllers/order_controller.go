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
		Status string `json:"status" binding:"required"`
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
	if err := config.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal memperbarui status order: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Status order berhasil diperbarui",
		"order":   order,
	})
}
