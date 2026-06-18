DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_producto$$

CREATE PROCEDURE sp_obtener_producto(
    IN p_codigo VARCHAR(50)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Validar si el cliente existe
    SELECT COUNT(*) INTO v_existe 
    FROM productos 
    WHERE codigo = p_codigo;

    IF v_existe > 0 THEN
        -- Si existe, devolvemos los datos y un flag de éxito
        SELECT
			id_producto,
			id_categoria,
			id_proveedor,
			codigo,
            nombre, 
            precio,
			impuesto,
            stock,
			stock_minimo,
            activo,
            200 AS status,
            'Producto encontrado' AS msg,
            1 AS ok
        FROM productos
        WHERE codigo = p_codigo;
    ELSE
        -- Si no existe, devolvemos un status 404 o informativo
        SELECT 
            404 AS status, 
            'No se encontró ningún producto con el código ingresado.' AS msg,
            0 AS ok;
    END IF;

END$$

DELIMITER ;