DELIMITER $$

DROP PROCEDURE IF EXISTS sp_eliminar_proveedor$$

CREATE PROCEDURE sp_eliminar_proveedor(
    IN p_identificacion VARCHAR(50)
)
BEGIN
    DECLARE v_id_proveedor INT DEFAULT 0;
    DECLARE v_cantidad_producto INT DEFAULT 0;

    -- Manejo de errores SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al intentar eliminar el proveedor' AS msg, 0 AS ok;
    END;

    START TRANSACTION;

    -- 1. Obtener el id_proveedor interno usando la identificación
    SELECT id_proveedor INTO v_id_proveedor
    FROM proveedores 
    WHERE identificacion = p_identificacion 
    LIMIT 1;

    -- Verificar si el proveedor existe en la tabla productos
    IF v_id_proveedor IS NULL OR v_id_proveedor = 0 THEN
        ROLLBACK;
        SELECT 404 AS status, 'El proveedor no existe' AS msg, 0 AS ok;
    ELSE
        -- 2. Validar si el id_proveedor tiene productos asociadas
        SELECT COUNT(*) INTO v_cantidad_producto 
        FROM productos 
        WHERE id_proveedor = v_id_proveedor;

        IF v_cantidad_producto > 0 THEN
            ROLLBACK;
            SELECT 400 AS status, 
                   CONCAT('Proveedor tiene ', v_cantidad_producto, ' producto(s) asociado(s) en el sistema.') AS msg, 
                   0 AS ok;
        ELSE
            -- 3. Si no tiene ventas, procedemos con el borrado físico
            DELETE FROM proveedores WHERE id_proveedor = v_id_proveedor;

            COMMIT;
            SELECT 200 AS status, 'Proveedor eliminado exitosamente' AS msg, 1 AS ok;
        END IF;
    END IF;

END$$

DELIMITER ;