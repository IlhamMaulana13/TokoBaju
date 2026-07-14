package controllers

import (
	"be-Baju/config"
	"be-Baju/models"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// SizeInput represents the input for sizes
type SizeInput struct {
	Size  string `json:"size" binding:"required"`
	Stock int    `json:"stock"`
}

// CreateProduct membuat produk baru
func CreateProduct(c *gin.Context) {
	var input struct {
		Name        string      `json:"name" binding:"required"`
		Description string      `json:"description"`
		Price       float64     `json:"price" binding:"required"`
		ImageURL    string      `json:"image_url"`
		Category    string      `json:"category"`
		Sizes       []SizeInput `json:"sizes"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var productSizes []models.ProductSize
	for _, s := range input.Sizes {
		productSizes = append(productSizes, models.ProductSize{
			Size:  s.Size,
			Stock: s.Stock,
		})
	}

	product := models.Product{
		Name:        input.Name,
		Description: input.Description,
		Price:       input.Price,
		ImageURL:    input.ImageURL,
		Category:    input.Category,
		Rating:      0.0,
		Sizes:       productSizes,
	}

	if err := config.DB.Create(&product).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat produk: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Produk berhasil dibuat",
		"product": product,
	})
}

// GetAllProducts mengambil semua produk
func GetAllProducts(c *gin.Context) {
	search := c.Query("search")
	query := config.DB.Model(&models.Product{})

	if search != "" {
		query = query.Where("name LIKE ?", "%"+search+"%")
	}

	var products []models.Product
	if err := query.Preload("Sizes").Find(&products).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil produk: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"products": products,
	})
}

// UpdateProduct memperbarui data produk
func UpdateProduct(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID produk tidak valid"})
		return
	}

	var product models.Product
	if err := config.DB.Preload("Sizes").First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Produk tidak ditemukan"})
		return
	}

	var input struct {
		Name        string      `json:"name" binding:"required"`
		Description string      `json:"description"`
		Price       float64     `json:"price" binding:"required"`
		ImageURL    string      `json:"image_url"`
		Category    string      `json:"category"`
		Sizes       []SizeInput `json:"sizes"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	product.Name = input.Name
	product.Description = input.Description
	product.Price = input.Price
	product.ImageURL = input.ImageURL
	product.Category = input.Category

	tx := config.DB.Begin()
	if err := tx.Save(&product).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal memperbarui produk: " + err.Error()})
		return
	}

	// Delete old sizes
	if err := tx.Where("product_id = ?", product.ID).Delete(&models.ProductSize{}).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menghapus ukuran lama: " + err.Error()})
		return
	}

	// Create new sizes
	for _, s := range input.Sizes {
		newSize := models.ProductSize{
			ProductID: product.ID,
			Size:      s.Size,
			Stock:     s.Stock,
		}
		if err := tx.Create(&newSize).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat ukuran baru: " + err.Error()})
			return
		}
	}

	tx.Commit()

	// Load product with sizes to return
	config.DB.Preload("Sizes").First(&product, product.ID)

	c.JSON(http.StatusOK, gin.H{
		"message": "Produk berhasil diperbarui",
		"product": product,
	})
}

// DeleteProduct menghapus produk
func DeleteProduct(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID produk tidak valid"})
		return
	}

	var product models.Product
	if err := config.DB.First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Produk tidak ditemukan"})
		return
	}

	if err := config.DB.Delete(&product).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menghapus produk: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Produk berhasil dihapus",
	})
}
