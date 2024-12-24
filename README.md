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

# Backend de API para Productos, Transacciones y Pagos

Este proyecto es un backend desarrollado en **Ruby** con **Sinatra**. Proporciona endpoints para gestionar productos, transacciones, clientes y pagos. Incluye funcionalidades como reducción de inventario, procesamiento de pagos y actualizaciones automáticas mediante webhooks.

## Requisitos

Antes de comenzar, asegúrate de tener instalado lo siguiente:

- Ruby (versión 2.7 o superior).
- Bundler (gem install bundler).
- Base de datos configurada (por ejemplo, PostgreSQL o SQLite).

## Instalación

1. Clona este repositorio:

   ```bash
   git clone <url-del-repositorio>
   cd <nombre-del-repositorio>
   ```

2. Instala las dependencias:

   ```bash
   bundle install
   ```

3. Configura las variables de entorno:

   Crea un archivo `.env` en la raíz del proyecto y define las variables necesarias (como configuraciones de la base de datos y claves de API externas):

   ```env
   DATABASE_URL=sqlite://db/development.sqlite3
   WOMPI_API_KEY=your_wompi_api_key
   ```

4. Configura la base de datos:

   ```bash
   rake db:create
   rake db:migrate
   rake db:seed
   ```

5. Ejecuta el servidor:

   ```bash
   ruby app.rb
   ```

   El backend estará disponible en `http://localhost:4567`.

## Endpoints
6. se enviaran en la collections de postman
### Productos

- **GET /products**
  - Lista todos los productos disponibles.

- **GET /products/:id**
  - Obtiene los detalles de un producto por su ID.

- **PUT /products/:id**
  - Actualiza la información de un producto.

- **DELETE /products/:id**
  - Elimina un producto por su ID.

- **PUT /products/:id/reduce-stock**
  - Reduce el inventario de un producto según una cantidad especificada.

### Transacciones

- **POST /transactions**
  - Crea una nueva transacción.

- **POST /transactions/pay**
  - Procesa el pago de una transacción. Requiere:
    - `transaction_id`
    - `expiration_time`
    - `customer_data`
    - `shipping_address`
    - `amount_in_cents`
    - `currency`
    - `payment_method`
    - `redirect_url`

- **GET /transactions/:id**
  - Obtiene los detalles de una transacción por su ID.

- **GET /transactions/:transaction_id/status**
  - Consulta el estado de una transacción.

- **GET /transactions**
  - Lista transacciones con filtros opcionales por estado y rango de fechas.

### Clientes

- **POST /customers**
  - Crea un nuevo cliente.

### Webhooks

- **POST /webhook/notifications**
  - Recibe notificaciones de eventos externos (como actualizaciones de transacciones).

## Pruebas

Las pruebas están implementadas con **RSpec** y **Rack::Test**. Incluyen casos para endpoints de transacciones y pagos.

### Ejecutar pruebas

Para ejecutar las pruebas:

```bash
rspec
```

Ejemplo de pruebas implementadas:

- **`spec/payment_service_spec.rb`**:
  - Verifica el procesamiento de pagos.
  - Prueba validaciones de campos obligatorios.
  - Simula errores internos para garantizar el manejo adecuado de excepciones.

- **`spec/transaction_service_spec.rb`**:
  - Prueba la creación y consulta de transacciones.

## Arquitectura

El backend está organizado de la siguiente manera:

- **`app.rb`**: Archivo principal que define los endpoints.
- **`config/`**: Configuración de la base de datos y otros ajustes globales.
- **`lib/services/`**: Contiene la lógica de negocio para productos, transacciones, pagos y clientes.
- **`spec/`**: Directorio de pruebas.

## Librerías principales

- [Sinatra](http://sinatrarb.com/): Framework web ligero.
- [Sinatra::Cors](https://github.com/ostinelli/sinatra-cors): Para manejo de CORS.
- [Dotenv](https://github.com/bkeepers/dotenv): Para manejo de variables de entorno.
- [RSpec](https://rspec.info/): Framework para pruebas.

## Contribuir

1. Haz un fork del repositorio.
2. Crea una rama para tu funcionalidad o corrección: `git checkout -b mi-nueva-funcionalidad`.
3. Haz commit de tus cambios: `git commit -m 'Agrega nueva funcionalidad'`.
4. Haz push a la rama: `git push origin mi-nueva-funcionalidad`.
5. Abre un Pull Request.

## Autor

Desarrollado por Edier camilo sandoval Roa.

