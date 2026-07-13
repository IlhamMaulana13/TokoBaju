package models

import "time"

type User struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	FirebaseUID string    `gorm:"type:varchar(100);uniqueIndex;not null" json:"firebase_uid"`
	Name        string    `gorm:"type:varchar(100);not null" json:"name"`
	Email       string    `gorm:"type:varchar(100);uniqueIndex;not null" json:"email"`
	Role        string    `gorm:"type:varchar(20);default:'customer'" json:"role"` // customer atau admin
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}