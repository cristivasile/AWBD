package app.restman.api.entities;

import jakarta.persistence.*;
import lombok.*;

import java.util.Set;

@Entity
@Setter
@Getter
@NoArgsConstructor
public class Product {

    @Id
    private String name;
    private double price;

    @ManyToOne(fetch=FetchType.LAZY)
    @JoinColumn(name = "categoryName")
    private MenuCategory category;

    @ManyToMany(mappedBy = "products")
    private Set<Order> orders;

    public Product(String name, double price, MenuCategory category) {
        this.name = name;
        this.price = price;
        this.category = category;
    }
}
