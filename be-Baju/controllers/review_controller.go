package controllers

import (
	"be-Baju/config"
	"be-Baju/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// CreateReview membuat ulasan produk dan mengupdate rating rata-rata produk
func CreateReview(c *gin.Context) {
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
		ProductID uint   `json:"product_id" binding:"required"`
		Rating    int    `json:"rating" binding:"required"`
		Comment   string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.Rating < 1 || input.Rating > 5 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Rating harus antara 1 dan 5"})
		return
	}

	review := models.Review{
		UserID:    user.ID,
		ProductID: input.ProductID,
		Rating:    input.Rating,
		Comment:   input.Comment,
	}

	tx := config.DB.Begin()

	if err := tx.Create(&review).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan review"})
		return
	}

	// Hitung rata-rata rating untuk produk tersebut
	var result struct {
		AvgRating float64
	}
	if err := tx.Model(&models.Review{}).
		Select("COALESCE(AVG(rating), 0) as avg_rating").
		Where("product_id = ?", input.ProductID).
		Scan(&result).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menghitung rata-rata rating"})
		return
	}

	// Update tabel produk
	if err := tx.Model(&models.Product{}).Where("id = ?", input.ProductID).Update("rating", result.AvgRating).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update rating produk"})
		return
	}

	tx.Commit()

	c.JSON(http.StatusCreated, gin.H{
		"message": "Review berhasil dikirim",
		"review":  review,
	})
}
