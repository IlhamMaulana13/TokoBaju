package controllers

import (
	"net/http"

	"be-Baju/config"
	"be-Baju/models"

	"github.com/gin-gonic/gin"
)

func SyncUser(c *gin.Context) {
	// Ambil UID yang di-set oleh middleware
	firebaseUID, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "UID tidak ditemukan di context"})
		return
	}

	uidStr := firebaseUID.(string)

	var user models.User
	// Cari user di MySQL berdasarkan Firebase UID
	result := config.DB.Where("firebase_uid = ?", uidStr).First(&user)

	// Jika tidak ketemu, berarti ini user baru (Register)
	if result.Error != nil {
		// Ambil data tambahan dari body request (misal nama dan email dari Flutter)
		var input struct {
			Name  string `json:"name" binding:"required"`
			Email string `json:"email" binding:"required"`
		}

		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		user = models.User{
			FirebaseUID: uidStr,
			Name:        input.Name,
			Email:       input.Email,
			Role:        "customer", // Default role
		}

		if err := config.DB.Create(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan user ke database"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"message": "User berhasil didaftarkan",
			"user":    user,
		})
		return
	}

	// Jika ketemu, kembalikan data user (Login)
	c.JSON(http.StatusOK, gin.H{
		"message": "Login berhasil",
		"user":    user,
	})
}