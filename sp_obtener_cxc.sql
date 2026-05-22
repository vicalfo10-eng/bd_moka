DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_cxc$$

CREATE PROCEDURE sp_obtener_cxc(
    IN p_id_cliente INT,
    IN p_numero_factura INT
)
BEGIN

    DECLARE v_existe INT DEFAULT 0;

    -- Validar si existen registros con los filtros proporcionados
    SELECT COUNT(*) INTO v_existe 
    FROM cuentas_cobrar cxc
    INNER JOIN ventas v ON cxc.id_venta = v.id_venta
    WHERE 
        (v.id_venta = p_numero_factura OR p_numero_factura = 0 OR p_numero_factura IS NULL)
        AND (cxc.id_cliente = p_id_cliente OR p_id_cliente = 0 OR p_id_cliente IS NULL);

    IF v_existe > 0 THEN

        SELECT 
            cxc.id_cxc AS id,
            v.id_venta AS invoice_number,
            cl.nombre AS customer_name,
            cxc.monto_total AS total_amount,
            cxc.saldo_pendiente AS current_balance,
            cxc.estado AS status_text,
            200 AS status,
            'Cuentas encontradas' AS msg,
            1 AS ok
        FROM cuentas_cobrar cxc
        INNER JOIN ventas v ON cxc.id_venta = v.id_venta
        INNER JOIN clientes cl ON cxc.id_cliente = cl.id_cliente
        WHERE 
            (v.id_venta = p_numero_factura OR p_numero_factura = 0 OR p_numero_factura IS NULL)
            AND (cxc.id_cliente = p_id_cliente OR p_id_cliente = 0 OR p_id_cliente IS NULL)
        ORDER BY v.id_venta DESC;

    ELSE

        SELECT 
            404 AS status, 
            'No se encontraron cuentas por cobrar con los criterios ingresados' AS msg,
            0 AS ok;
    END IF;

END$$

DELIMITER ;