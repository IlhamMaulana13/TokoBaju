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

	// Endpoint Admin (Wajib bawa token Firebase & Memiliki role Admin)
	admin := r.Group("/api/admin")
	admin.Use(middleware.FirebaseAuth(), middleware.AdminOnly())
	{
		// CRUD Produk
		admin.POST("/products", controllers.CreateProduct)
		admin.GET("/products", controllers.GetAllProducts)
		admin.PUT("/products/:id", controllers.UpdateProduct)
		admin.DELETE("/products/:id", controllers.DeleteProduct)

		// Kelola Pesanan
		admin.GET("/orders", controllers.GetAllOrders)
		admin.PUT("/orders/:id/status", controllers.UpdateOrderStatus)
	}

	return r
}