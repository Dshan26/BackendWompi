# Backend API for Payment Processing App

## Descripción
Este proyecto consiste en un backend robusto y escalable diseñado para gestionar el procesamiento de pagos mediante la plataforma Wompi. La aplicación incluye funcionalidades para la gestión de transacciones, actualizaciones de stock, manejo de entregas, y más, cumpliendo con los requisitos establecidos en el test de desarrollo FullStack.

## Funcionalidades principales
1. **Gestión de productos:**
   - Mostrar productos con su precio y unidades disponibles en el stock.
2. **Procesamiento de pagos:**
   - Validación y creación de transacciones utilizando la API de Wompi en modo sandbox.
   - Gestión del flujo de estados de transacción: `PENDING`, `APPROVED`, `DECLINED`.
3. **Actualización de stock:**
   - Reducción del inventario una vez que un pago es aprobado.
4. **Entrega de productos:**
   - Registro y manejo de información de entregas para clientes.
5. **Validaciones robustas:**
   - Verificación de datos de entrada y manejo de errores en todos los endpoints.

## Tecnologías utilizadas
- **Ruby** para la lógica del backend.
- **Sequel** como ORM para la gestión de la base de datos.
- **PostgreSQL** como base de datos relacional.
- **RSpec** para las pruebas unitarias y de integración.

## Arquitectura
- **Patrón Hexagonal (Ports & Adapters):** Separación de la lógica de negocio, capa de infraestructura y controladores para mejorar la mantenibilidad y escalabilidad.
- **Railway Oriented Programming (ROP):** Uso de flujos de éxito y error para simplificar el manejo de lógica de negocio.

## Configuración e instalación
1. Clona este repositorio:
   ```bash
   git clone https://github.com/tuusuario/name-project.git
   cd name-file

## .ENV
1. crear el .env y sacar la info de config-wompi.rb
WOMPI_CONFIG = {
  public_key: ENV['WOMPI_PUBLIC_KEY'] || "pub_stagtest_g2u0HQd3ZMh05hsSgTS2lUV8t3s4mOt7",
  private_key: ENV['WOMPI_PRIVATE_KEY'] || "prv_stagtest_5i0ZGIGiFcDQifYsXxvsny7Y37tKqFWg",
  sandbox_url: ENV['WOMPI_SANDBOX_URL'] || "https://api-sandbox.co.uat.wompi.dev/v1",
  integrity_secret: ENV['WOMPI_INTEGRITY_SECRET'] || "stagtest_integrity_nAIBuqayW70XpUqJS4qf4STYiISd89Fp"
}.freeze
