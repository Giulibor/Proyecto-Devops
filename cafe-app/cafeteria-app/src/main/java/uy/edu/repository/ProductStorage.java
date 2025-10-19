package uy.edu.ucu.cafeteria_app.repository;

import org.springframework.stereotype.Component;
import uy.edu.ucu.cafeteria_app.model.Product;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Component
public class ProductStorage {
    private final Map<Long, Product> data = new ConcurrentHashMap<>();
    private final AtomicLong seq = new AtomicLong(0);

    public Product save(Product p) {
        if (p.getId() == null) p.setId(seq.incrementAndGet());
        data.put(p.getId(), p);
        return p;
    }

    public Optional<Product> findById(Long id) { return Optional.ofNullable(data.get(id)); }
    public List<Product> findAll() { return new ArrayList<>(data.values()); }
    public void delete(Long id) { data.remove(id); }
    public boolean exists(Long id) { return data.containsKey(id); }
}
