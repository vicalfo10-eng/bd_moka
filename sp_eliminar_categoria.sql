DELIMITER $$

DROP PROCEDURE IF EXISTS sp_eliminar_categoria$$

CREATE PROCEDURE sp_eliminar_categoria(
    IN p_id_categoria INT
)
BEGIN

    DECLARE v_con_productos INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al eliminar la categoría' AS msg, 0 AS ok;
    END;

    START TRANSACTION;

    -- Verificar si tiene productos asociados
    SELECT COUNT(*) INTO v_con_productos
	FROM productos
	WHERE id_categoria = p_id_categoria;

    IF v_con_productos > 0 THEN
        ROLLBACK;
        SELECT 400 AS status, 
               CONCAT('Existen ', v_con_productos, ' productos asociados a esta categoría.') AS msg, 
               0 AS ok;
    ELSE
	
        DELETE FROM categorias WHERE id_categoria = p_id_categoria;
		
        COMMIT;
		
        SELECT 200 AS status, 'Categoría eliminada exitosamente' AS msg, 1 AS ok;
		
    END IF;
	
END$$

DELIMITER ;