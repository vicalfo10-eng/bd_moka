-- ==========================================
-- CREACIÓN DE BASE DE DATOS
-- ==========================================

CREATE DATABASE IF NOT EXISTS mokadb
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE mokadb;

-- ==========================================
-- TABLA: ROLES
-- ==========================================

CREATE TABLE roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
	activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- TABLA: USUARIOS
-- ==========================================

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    id_rol INT NOT NULL,
	identificacion VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Índices adicionales
CREATE INDEX idx_usuarios_rol ON usuarios(id_rol);
CREATE INDEX idx_usuarios_activo ON usuarios(activo);
CREATE INDEX idx_usuarios_identificacion ON usuarios(identificacion);

-- ==========================================
-- TABLA: CATEGORIAS
-- ==========================================

CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
	activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- TABLA: PROVEEDORES
-- ==========================================

CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
	identificacion VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(150),
    direccion VARCHAR(255),
	activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_proveedores_identificacion ON proveedores(identificacion);
CREATE INDEX idx_proveedores_nombre ON proveedores(nombre);

-- ==========================================
-- TABLA: PRODUCTOS
-- ==========================================

CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    id_proveedor INT NOT NULL,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    precio DECIMAL(12,2) NOT NULL,
	impuesto DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    stock INT DEFAULT 0,
    stock_minimo INT DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_producto_proveedor
        FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Índices adicionales
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_proveedor ON productos(id_proveedor);
CREATE INDEX idx_productos_nombre ON productos(nombre);
CREATE INDEX idx_productos_stock_minimo ON productos(stock_minimo);
CREATE INDEX idx_productos_activo ON productos(activo);

-- ==========================================
-- TABLA: CLIENTES
-- ==========================================

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
	identificacion VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(150),
    direccion VARCHAR(255),
	activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clientes_nombre ON clientes(nombre);
CREATE INDEX idx_clientes_identificacion ON clientes(identificacion);

-- ==========================================
-- TABLA: MOVIMIENTOS INVENTARIO
-- ==========================================

CREATE TABLE movimientos_inventario (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo ENUM('ENTRADA','SALIDA') NOT NULL,
    cantidad INT NOT NULL,
    descripcion VARCHAR(255),
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_movimiento_producto
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_movimiento_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE INDEX idx_movimientos_producto ON movimientos_inventario(id_producto);
CREATE INDEX idx_movimientos_usuario ON movimientos_inventario(id_usuario);
CREATE INDEX idx_movimientos_tipo ON movimientos_inventario(tipo);
CREATE INDEX idx_movimientos_fecha ON movimientos_inventario(fecha_creacion);

-- ==========================================
-- TABLA: VENTAS
-- ==========================================

CREATE TABLE ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    tipo_pago ENUM('CONTADO', 'CREDITO') NOT NULL,
    estado_pago ENUM('PAGADA', 'PENDIENTE', 'ANULADA') NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_venta_cliente
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_venta_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE INDEX idx_ventas_cliente ON ventas(id_cliente);
CREATE INDEX idx_ventas_usuario ON ventas(id_usuario);
CREATE INDEX idx_ventas_tipo_estado ON ventas(tipo_pago, estado_pago);
CREATE INDEX idx_ventas_fecha ON ventas(fecha_creacion);

-- Índice compuesto para reportes frecuentes
CREATE INDEX idx_ventas_fecha_usuario 
ON ventas(fecha_creacion, id_usuario);

-- ==========================================
-- TABLA: DETALLE VENTAS
-- ==========================================

CREATE TABLE detalle_ventas (
    id_detalle_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	impuesto DECIMAL(5,2) NOT NULL DEFAULT 0.00,
	total_impuesto DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	descuento DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	total_linea DECIMAL(12,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT fk_detalle_venta
        FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE INDEX idx_detalle_venta_venta ON detalle_ventas(id_venta);
CREATE INDEX idx_detalle_venta_producto ON detalle_ventas(id_producto);

-- ===========================================================
-- TABLA: CONFIGURAR LOS PLAZOS Y FRECUENCIAS DE LOS CREDITOS
-- ===========================================================

CREATE TABLE configuracion_creditos (
    id_config INT AUTO_INCREMENT PRIMARY KEY,
    nombre_plan VARCHAR(100) NOT NULL,
    frecuencia_dias INT NOT NULL,
    cantidad_cuotas INT NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_config_activo ON configuracion_creditos(activo);

-- ================================================
-- TABLA: CUENTAS POR COBRAR PARA VENTAS A CREDITO
-- ================================================

CREATE TABLE cuentas_cobrar (
    id_cxc INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_cliente INT NOT NULL,
    id_config INT NOT NULL,
    monto_total DECIMAL(12,2) NOT NULL,
    saldo_pendiente DECIMAL(12,2) NOT NULL,
    estado ENUM('VIGENTE', 'CANCELADA', 'MORA', 'ANULADA') DEFAULT 'VIGENTE' NOT NULL,
    fecha_vencimiento_total DATE NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cxc_venta 
        FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_cxc_cliente 
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_cxc_config 
        FOREIGN KEY (id_config) REFERENCES configuracion_creditos(id_config)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_cxc_venta ON cuentas_cobrar(id_venta);
CREATE INDEX idx_cxc_cliente_estado ON cuentas_cobrar(id_cliente, estado);
CREATE INDEX idx_cxc_estado ON cuentas_cobrar(estado);
CREATE INDEX idx_cxc_vencimiento ON cuentas_cobrar(fecha_vencimiento_total);

-- ================================================
-- TABLA: PLAN DE PAGOS PARA VENTAS A CREDITO
-- ================================================

CREATE TABLE plan_pagos (
    id_cuota INT AUTO_INCREMENT PRIMARY KEY,
    id_cxc INT NOT NULL,
    numero_cuota INT NOT NULL,
    monto_cuota DECIMAL(12,2) NOT NULL,
    saldo_cuota DECIMAL(12,2) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado ENUM('PENDIENTE', 'PAGADA', 'PARCIAL', 'MORA') DEFAULT 'PENDIENTE' NOT NULL,
    fecha_pago_real DATETIME NULL,

    CONSTRAINT fk_plan_cxc 
        FOREIGN KEY (id_cxc) REFERENCES cuentas_cobrar(id_cxc)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX idx_plan_cxc ON plan_pagos(id_cxc);
CREATE INDEX idx_plan_vencimiento ON plan_pagos(fecha_vencimiento);
CREATE INDEX idx_plan_estado ON plan_pagos(estado);

-- ================================================
-- TABLA: ABONOS PARA VENTAS A CREDITO
-- ================================================

CREATE TABLE abonos_credito (
    id_abono INT AUTO_INCREMENT PRIMARY KEY,
    id_cxc INT NOT NULL,
    id_usuario INT NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    metodo_pago ENUM('EFECTIVO', 'TRANSFERENCIA', 'SINPE', 'TARJETA') NOT NULL,
    comprobante VARCHAR(100) NULL,
    fecha_abono DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_abono_cxc 
        FOREIGN KEY (id_cxc) REFERENCES cuentas_cobrar(id_cxc)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_abono_usuario 
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_abono_cxc ON abonos_credito(id_cxc);
CREATE INDEX idx_abono_fecha ON abonos_credito(fecha_abono);
CREATE INDEX idx_abono_usuario ON abonos_credito(id_usuario);

-- ==========================================
-- INSERTAR ROLES INICIALES
-- ==========================================

INSERT INTO roles (nombre) VALUES ('ADMINISTRADOR');
INSERT INTO roles (nombre) VALUES ('VENDEDOR');

-- ==========================================
-- INSERTAR USUARIO INICIALES
-- ==========================================

INSERT INTO usuarios (id_rol, identificacion, nombre, correo, contrasena, activo) VALUES (1, '206750143', 'Victor Granados', 'vicalfo10@gmail.com', '$2b$10$1JqJt8QSnWgOIcfFJ85T4.N1rUQ/KbLO58/.CwgQNlPzL8e9MWz.a', 1);

-- ===========================================
-- INSERTAR CONGIFURACIÓN DE CRÉDITOS INICIAL
-- ===========================================

INSERT INTO configuracion_creditos (nombre_plan, frecuencia_dias, cantidad_cuotas) VALUES ('Trimestral Quincenal', 15, 6);
INSERT INTO configuracion_creditos (nombre_plan, frecuencia_dias, cantidad_cuotas) VALUES ('Trimestral Mensual', 30, 3);