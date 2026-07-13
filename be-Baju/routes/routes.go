package routes

import (
	"be-Baju/controllers"
	"be-Baju/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// Endpoint Public (Tidak perlu token)
	api := r.Group("/api")
	{
		api.GET("/ping", func(c *gin.Context) {
			c.JSON(200, gin.H{"message": "Server be-Baju aman 🚀"})
		})
	}

	// Endpoint Protected (Wajib bawa token Firebase)
	protected := r.Group("/api")
	protected.Use(middleware.FirebaseAuth())
	{
		// Endpoint untuk sinkronisasi data user dari Firebase ke MySQL
		protected.POST("/auth/sync", controllers.SyncUser)
	}

	return r
}