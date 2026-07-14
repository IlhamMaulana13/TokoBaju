package models

import "time"

type Order struct {
	ID              uint        `gorm:"primaryKey" json:"id"`
	UserID          uint        `gorm:"not null" json:"user_id"`
	User            User        `gorm:"foreignKey:UserID" json:"user,omitempty"`
	TotalPrice      float64     `gorm:"type:decimal(10,2);not null" json:"total_price"`
	PaymentMethod   string      `gorm:"type:varchar(20);default:'COD'" json:"payment_method"`
	Status          string      `gorm:"type:varchar(50);default:'Pending'" json:"status"` // Pending, Packing, Shipped, Delivered
	ProofOfDelivery string      `gorm:"type:text" json:"proof_of_delivery"`
	ShippingAddress string      `gorm:"type:text;not null" json:"shipping_address"`
	OrderItems      []OrderItem `gorm:"foreignKey:OrderID" json:"items"`
	CreatedAt       time.Time   `json:"created_at"`
	UpdatedAt       time.Time   `json:"updated_at"`
}

type OrderItem struct {
	ID        uint    `gorm:"primaryKey" json:"id"`
	OrderID   uint    `gorm:"not null" json:"order_id"`
	ProductID uint    `gorm:"not null" json:"product_id"`
	Product   Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
	Size      string  `gorm:"type:varchar(50);not null" json:"size"`
	Quantity  int     `gorm:"not null" json:"quantity"`
	SubTotal  float64 `gorm:"type:decimal(10,2);not null" json:"sub_total"`
}
