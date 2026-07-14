package middleware

import (
	"be-Baju/config"
	"be-Baju/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// AdminOnly memverifikasi apakah user memiliki role admin
func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		firebaseUID, exists := c.Get("firebase_uid")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: Firebase UID tidak ditemukan"})
			c.Abort()
			return
		}

		uidStr := firebaseUID.(string)

		var user models.User
		// Cari user di database berdasarkan FirebaseUID
		if err := config.DB.Where("firebase_uid = ?", uidStr).First(&user).Error; err != nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: User tidak terdaftar di sistem"})
			c.Abort()
			return
		}

		// Cek apakah role-nya admin
		if user.Role != "admin" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: Hanya admin yang dapat mengakses resource ini"})
			c.Abort()
			return
		}

		c.Next()
	}
}
