package uy.edu.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uy.edu.metrics.OrderMetrics;
import uy.edu.model.CoffeeOrder;
import uy.edu.model.OrderStatus;
import uy.edu.repository.CoffeeOrderRepository;
import io.micrometer.core.instrument.MeterRegistry;

import java.util.List;

@Service
@Transactional
public class OrderService {

  private final CoffeeOrderRepository coffeeOrderRepo;
  private final OrderMetrics metrics;
  private final MeterRegistry meterRegistry;

  public OrderService(CoffeeOrderRepository coffeeOrderRepo, OrderMetrics metrics, MeterRegistry meterRegistry) {
    this.coffeeOrderRepo = coffeeOrderRepo;
    this.metrics = metrics;
    this.meterRegistry = meterRegistry;
  }

  public CoffeeOrder create(CoffeeOrder o) {
    CoffeeOrder saved = coffeeOrderRepo.save(o);
    metrics.incCreated();

    String product = (saved.getDrink() != null && !saved.getDrink().isBlank())
        ? saved.getDrink()
        : "unknown";

    int qty = Math.max(1, saved.getQuantity());
    meterRegistry
        .counter("coffee_orders_created", "product", product)
        .increment(qty);

    return saved;
  }

  @Transactional(readOnly = true)
  public List<CoffeeOrder> list() {
    return coffeeOrderRepo.findAll();
  }

  @Transactional(readOnly = true)
  public CoffeeOrder get(Long id) {
    return coffeeOrderRepo.findById(id)
        .orElseThrow(() -> new NotFoundException("Order " + id + " not found"));
  }

  public CoffeeOrder updateStatus(Long id, OrderStatus status) {
    CoffeeOrder o = get(id);
    boolean wasDelivered = (o.getStatus() == OrderStatus.DELIVERED);

    o.setStatus(status);
    CoffeeOrder saved = coffeeOrderRepo.save(o);

    if (status == OrderStatus.DELIVERED && !wasDelivered) {
      metrics.incDelivered();

      String product = (saved.getDrink() != null && !saved.getDrink().isBlank())
          ? saved.getDrink()
          : "unknown";

      int qty = Math.max(1, saved.getQuantity());
      meterRegistry
          .counter("coffee_orders_delivered", "product", product)
          .increment(qty);
    }

    return saved;
  }

  public void delete(Long id) {
    if (!coffeeOrderRepo.existsById(id)) {
      throw new NotFoundException("Order " + id + " not found");
    }
    coffeeOrderRepo.deleteById(id);
  }

  // Excepción checked/unchecked simple para 404
  public static class NotFoundException extends RuntimeException {
    public NotFoundException(String m) {
      super(m);
    }
  }
}
