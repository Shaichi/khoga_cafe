package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "menuitems")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class MenuItem extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;
    @Column(columnDefinition = "nvarchar(255)")
    private String name;
    private BigDecimal price;
    @Column(columnDefinition = "nvarchar(255)")
    private String description;
    private Boolean isActive;
    @Column(columnDefinition = "nvarchar(255)")
    private String imageUrl;
    @Column(columnDefinition = "nvarchar(255)")
    private String barcode;
    @Column(columnDefinition = "nvarchar(255)")
    private String abbreviation;
    private Boolean isDeleted;
    
    // For variants
    @Column(name = "parent_item_id")
    private UUID parentItemId;
    
    @Column(columnDefinition = "nvarchar(255)")
    private String sku;
    
    @Column(name = "size_name", columnDefinition = "nvarchar(255)")
    private String sizeName; // S, M, L
}
