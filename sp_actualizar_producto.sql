DELIMITER $$

DROP PROCEDURE IF EXISTS sp_actualizar_producto$$

CREATE PROCEDURE sp_actualizar_producto(
	IN p_categoria INTEGER,
	IN p_proveedor INTEGER,
	IN p_codigo VARCHAR(50),
    IN p_nombre VARCHAR(150),
	IN p_precio DECIMAL(10,2),
	IN p_impuesto DECIMAL(5,2),
    IN p_stock INTEGER,
	IN p_stockmin INTEGER,
	IN p_activo TINYINT
)
BEGIN

    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al actualizar el producto' AS msg, 0 AS ok;
    END;

    START TRANSACTION;
	
	-- Realizar la actualización
	UPDATE productos 
	SET id_categoria = p_categoria,
		id_proveedor = p_proveedor,
		nombre = p_nombre,
		precio = p_precio,
		impuesto = p_impuesto,
		stock = p_stock,
		stock_minimo = p_stockmin,
		activo = p_activo
	WHERE codigo = p_codigo;

	COMMIT;
		
	SELECT 200 AS status, 'Producto actualizado correctamente' AS msg, 1 AS ok;

END$$

DELIMITER ;