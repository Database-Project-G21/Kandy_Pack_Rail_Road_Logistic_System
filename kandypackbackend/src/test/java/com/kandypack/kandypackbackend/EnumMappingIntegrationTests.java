package com.kandypack.kandypackbackend;

import com.kandypack.kandypackbackend.entity.Customer;
import com.kandypack.kandypackbackend.entity.CustomerOrder;
import com.kandypack.kandypackbackend.entity.StaffUser;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
@EnabledIfEnvironmentVariable(named = "KP_ENUM_TEST_DATABASE", matches = "true")
class EnumMappingIntegrationTests {
    @Autowired EntityManager entityManager;
    @Autowired JdbcTemplate jdbc;

    @Test
    void staffRoleRoundTripsThroughNativeEnum() {
        StaffUser staff = new StaffUser();
        staff.setStaffId("ENUMTEST01");
        staff.setStaffName("Enum Test");
        staff.setEmail("enum-test@example.invalid");
        staff.setPassword("test-only-hash");
        staff.setRole("ADMIN");
        entityManager.persist(staff);
        entityManager.flush();
        entityManager.clear();

        StaffUser loaded = entityManager.find(StaffUser.class, "ENUMTEST01");
        assertEquals("ADMIN", loaded.getRole());
        loaded.setRole("DISPATCHER");
        entityManager.flush();
        entityManager.clear();
        assertEquals("DISPATCHER", entityManager.find(StaffUser.class, "ENUMTEST01").getRole());
        assertEquals("staff_role", jdbc.queryForObject(
                "SELECT pg_typeof(role)::text FROM public.staff_user WHERE staff_id='ENUMTEST01'", String.class));
    }

    @Test
    void orderStatusRoundTripsAndPassesCancellationTriggers() {
        Customer customer = entityManager.createQuery("SELECT c FROM Customer c", Customer.class)
                .setMaxResults(1).getSingleResult();
        CustomerOrder order = new CustomerOrder();
        order.setOrderId("ENUMTEST02");
        order.setCustomer(customer);
        order.setAmount(BigDecimal.ZERO);
        order.setPlacementDate(LocalDate.now());
        order.setDeliveryDate(LocalDate.now().plusDays(8));
        order.setStatus("placed");
        entityManager.persist(order);
        entityManager.flush();
        entityManager.clear();

        CustomerOrder loaded = entityManager.find(CustomerOrder.class, "ENUMTEST02");
        assertEquals("placed", loaded.getStatus());
        loaded.setStatus("cancelled");
        entityManager.flush();
        entityManager.clear();
        assertEquals("cancelled", entityManager.find(CustomerOrder.class, "ENUMTEST02").getStatus());
        assertEquals("order_status", jdbc.queryForObject(
                "SELECT pg_typeof(status)::text FROM public.customer_order WHERE order_id='ENUMTEST02'", String.class));
    }

    @Test
    void deliveryHistoryReportsExposeStatusAsText() {
        Object status = jdbc.queryForList(
                "SELECT status FROM public.view_customer_delivery_history LIMIT 1").getFirst().get("status");
        assertInstanceOf(String.class, status);
    }

    @Test
    void databaseRejectsUnknownEnumLabels() {
        assertThrows(DataAccessException.class,
                () -> jdbc.queryForObject("SELECT 'unknown'::public.order_status", String.class));
    }
}
