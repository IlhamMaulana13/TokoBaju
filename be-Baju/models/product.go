package models

import "time"

type ProductSize struct {
	ID        uint   `gorm:"primaryKey" json:"id"`
	ProductID uint   `gorm:"not null" json:"product_id"`
	Size      string `gorm:"type:varchar(50);not null" json:"size"`
	Stock     int    `gorm:"not null" json:"stock"`
}

type Product struct {
	ID          uint          `gorm:"primaryKey" json:"id"`
	Name        string        `gorm:"type:varchar(255);not null" json:"name"`
	Description string        `gorm:"type:text" json:"description"`
	Price       float64       `gorm:"type:decimal(10,2);not null" json:"price"`
	ImageURL    string        `gorm:"type:text" json:"image_url"` // URL gambar dari Firebase Storage
	Category    string        `gorm:"type:varchar(100);default:'Semua';not null" json:"category"`
	Rating      float64       `gorm:"type:decimal(3,1);default:0.0;not null" json:"rating"`
	Sizes       []ProductSize `gorm:"foreignKey:ProductID;constraint:OnDelete:CASCADE;" json:"sizes"`
	CreatedAt   time.Time     `json:"created_at"`
	UpdatedAt   time.Time     `json:"updated_at"`
}
