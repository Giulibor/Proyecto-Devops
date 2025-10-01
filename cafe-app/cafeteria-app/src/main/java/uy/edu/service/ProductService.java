package uy.edu.ucu.cafeteria_app.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import uy.edu.ucu.cafeteria_app.model.Product;
import uy.edu.ucu.cafeteria_app.repository.ProductStorage;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductService {
    private final ProductStorage storage;

    public Product create(Product p) { return storage.save(p); }
    public Product update(Long id, Product p) {
        if (!storage.exists(id)) throw new IllegalArgumentException("Product not found");
        p.setId(id);
        return storage.save(p);
    }
    public void delete(Long id) { storage.delete(id); }
    public Product get(Long id) {
        return storage.findById(id).orElseThrow(() -> new IllegalArgumentException("Product not found"));
    }
    public List<Product> list() { return storage.findAll(); }
    public boolean exists(Long id) { return storage.exists(id); }
}
