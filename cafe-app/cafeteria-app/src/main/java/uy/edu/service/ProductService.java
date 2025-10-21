package uy.edu.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import uy.edu.model.Product;
import uy.edu.repository.ProductRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductService {
    private final ProductRepository product;

    public Product create(Product p) { return product.save(p); }
    public Product update(Long id, Product p) {
        if (!product.existsById(id)) throw new IllegalArgumentException("Product not found");
        p.setId(id);
        return product.save(p);
    }
    public void delete(Long id) { product.deleteById(id); }
    public Product get(Long id) {
        return product.findById(id).orElseThrow(() -> new IllegalArgumentException("Product not found"));
    }
    public List<Product> list() { return product.findAll(); }
    public boolean exists(Long id) { return product.existsById(id); }
}
