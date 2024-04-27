package app.restman.api.services;

import app.restman.api.DTOs.ProductDTO;
import app.restman.api.entities.MenuCategory;
import app.restman.api.entities.Product;
import app.restman.api.repositories.MenuCategoryRepository;
import app.restman.api.repositories.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

@Service
public class ProductService {

    private final ProductRepository productRepository;
    private final MenuCategoryRepository menuCategoryRepository;

    @Autowired
    public ProductService(ProductRepository productRepository, MenuCategoryRepository menuCategoryRepository)
    {
        this.productRepository = productRepository;
        this.menuCategoryRepository = menuCategoryRepository;
    }

    public List<Product> getAllProducts()
    {
        return productRepository.findAll();
    }

    public Product getProductByName(String id)
    {
        return productRepository.findById(id).orElse(null);
    }

    public List<Product> getProductsByNames(List<String> productNames) throws Exception {
        List<Product> products = new ArrayList<>();
        for (var productName : productNames){
            if (!productRepository.existsById(productName))
                throw new Exception("Product with name " + productName + " does not exist!");

            Product product = productRepository.getReferenceById(productName);
            products.add(product);
        }

        return products;
    }

    public Product createProduct(ProductDTO productDTO) throws Exception {

        /*
        if (!menuCategoryRepository.existsById(productDTO.getCategoryName()))
            throw new Exception("Menu category does not exist!");
         */

        if (productDTO.getPrice() < 0)
            throw new Exception("Price cannot be negative!");

        if (productDTO.getName().isBlank())
            throw new Exception("Name cannot be blank!");

        Product product = new Product();
        product.setName(productDTO.getName());
        product.setPrice(productDTO.getPrice());
        //TODO - implement
        //product.setCategory(menuCategoryRepository.getReferenceById(productDTO.getCategoryName()));

        return productRepository.save(product);
    }

    public void updateProduct(String productName, ProductDTO updatedProductDTO) throws NoSuchElementException, Exception{
        /*
        if (!menuCategoryRepository.existsById(updatedProductDTO.getCategoryName()))
            throw new Exception("Menu category does not exist!");
         */

        if (updatedProductDTO.getPrice() < 0)
            throw new Exception("Price cannot be negative!");

        if (updatedProductDTO.getName().isBlank())
            throw new Exception("Name cannot be blank!");

        Product product = productRepository.findById(productName).orElse(null);
        if (product != null) {
            // Update product details
            product.setPrice(updatedProductDTO.getPrice());
            //TODO - implement
            //product.setCategory(menuCategoryRepository.getReferenceById(updatedProductDTO.getCategoryName()));

            for (var order : product.getOrders())
                order.calculatePrice();

            productRepository.save(product);
        }
        else
        {
            throw new NoSuchElementException("Product does not exist!");
        }
    }

    public void deleteProduct(String productName) throws NoSuchElementException{
        if (!productRepository.existsById(productName))
            throw new NoSuchElementException("Product does not exist!");

        productRepository.deleteById(productName);
    }
}
