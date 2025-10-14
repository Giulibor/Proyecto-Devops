package uy.edu.ucu.cafeteria_app.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uy.edu.ucu.cafeteria_app.metrics.OrderMetrics;
import uy.edu.ucu.cafeteria_app.model.CoffeeOrder;
import uy.edu.ucu.cafeteria_app.model.OrderStatus;
import uy.edu.ucu.cafeteria_app.repo.CoffeeOrderRepository;

import java.util.List;

@Service
@Transactional
public class OrderService {

    private final CoffeeOrderRepository repo;
    private final OrderMetrics metrics;

    public OrderService(CoffeeOrderRepository repo, OrderMetrics metrics) {
        this.repo = repo;
        this.metrics = metrics;
    }

    public CoffeeOrder create(CoffeeOrder o) {
        CoffeeOrder saved = repo.save(o);
        metrics.incCreated();
        return saved;
    }

    @Transactional(readOnly = true)
    public List<CoffeeOrder> list() {
        return repo.findAll();
    }

    @Transactional(readOnly = true)
    public CoffeeOrder get(Long id) {
        return repo.findById(id)
                .orElseThrow(() -> new NotFoundException("Order " + id + " not found"));
    }

    public CoffeeOrder updateStatus(Long id, OrderStatus status) {
        CoffeeOrder o = get(id);
        o.setStatus(status);
        CoffeeOrder saved = repo.save(o);
        if (status == OrderStatus.DELIVERED) {
            metrics.incDelivered();
        }
        return saved;
    }

    public void delete(Long id) {
        if (!repo.existsById(id)) {
            throw new NotFoundException("Order " + id + " not found");
        }
        repo.deleteById(id);
    }

    // Excepción checked/unchecked simple para 404
    public static class NotFoundException extends RuntimeException {
        public NotFoundException(String m) { super(m); }
    }
}
