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
		api.GET("/products", controllers.GetAllProducts)
	}

	// Endpoint Protected (Wajib membawa token Firebase)
	protected := r.Group("/api")
	protected.Use(middleware.FirebaseAuth())
	{
		protected.POST("/auth/sync", controllers.SyncUser)

		// TAMBAHKAN DUA LINE INI DI DALAM PROTECTED GROUP
		protected.POST("/orders", controllers.CreateOrder)
		protected.GET("/orders/history", controllers.GetCustomerOrders)

		protected.POST("/reviews", controllers.CreateReview)
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
		admin.GET("/reports", controllers.GetSalesReport)
	}

	return r
}
