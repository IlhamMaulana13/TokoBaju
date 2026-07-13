package middleware

import (
	"context"
	"net/http"
	"strings"

	"be-Baju/config"

	"github.com/gin-gonic/gin"
)

// FirebaseAuthMiddleware memverifikasi token dari Flutter
func FirebaseAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: Token tidak ditemukan"})
			c.Abort()
			return
		}

		idToken := strings.TrimPrefix(authHeader, "Bearer ")

		// Verifikasi token menggunakan Firebase Admin SDK
		client, err := config.FirebaseApp.Auth(context.Background())
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal inisialisasi Firebase Auth Client"})
			c.Abort()
			return
		}

		token, err := client.VerifyIDToken(context.Background(), idToken)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: Token tidak valid"})
			c.Abort()
			return
		}

		// Simpan UID Firebase ke dalam context Gin agar bisa dipakai di Controller
		c.Set("firebase_uid", token.UID)
		c.Next()
	}
}