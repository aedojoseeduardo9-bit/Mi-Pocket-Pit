# Pagos con Google Play (plan)

Hoy (`Pagos.MODO_PRUEBA = true`): tocar un paquete muestra "Comprar gratis" y entrega las bellotas sin cobrar.

## Pasos para activarlo de verdad
1. **Play Console**: crear la app `com.nioro.pocketpip` (gratuita, sin anuncios, categoría Juegos › Casual,
   público objetivo con niños → programa "Familias").
2. **Productos integrados** (consumibles): `bellotas_500`, `bellotas_1200`, `bellotas_3500`, `bellotas_8000`,
   `bellotas_20000` (los mismos id de `data/catalogo.json`).
3. **Plugin oficial de Godot** "GodotGooglePlayBilling" en `godot/android/plugins/` + compilación con Gradle
   (`gradle_build/use_gradle_build=true`).
4. En `pagos.gd`: conectar al iniciar, consultar precios (mostrar el precio local que entrega Google, no el fijo),
   `purchase(sku)`, y al recibir la compra **consumirla** (`consume_purchase`) antes de entregar las bellotas.
   Al abrir la app, revisar compras pendientes (por si se cerró a mitad).
5. Subir un AAB firmado con la **llave de subida** a la pista de prueba interna y probar con cuentas de prueba
   (las compras de prueba de Google no cobran).
6. Más adelante: verificación en servidor (anti-trampas) y pase mensual (suscripción).
