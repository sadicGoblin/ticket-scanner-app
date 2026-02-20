# Ticket Scanner - Rinno

App Flutter para canjear (quemar) tickets en el casino. Se usa en el punto de entrega para verificar y marcar tickets como cobrados.

## Estados de Ticket

| Estado     | Descripcion                           |
| ---------- | ------------------------------------- |
| `pending`  | Asignado, aun no impreso en kiosco    |
| `printed`  | Impreso en kiosco, listo para canjear |
| `redeemed` | Cobrado/quemado en el casino          |

## Funcionalidades

- **Escaneo QR/Barcode**: Usa la camara para escanear el codigo del ticket
- **Ingreso manual**: Permite escribir el codigo del ticket manualmente
- **Canjear ticket**: Envia PATCH a la API para cambiar status a `redeemed`
- **Configuracion**: Permite cambiar la URL del servidor API

## Configuracion

La URL del servidor por defecto es `http://192.168.100.10:8051`.
Se puede cambiar desde Configuracion (icono engranaje).

## API Endpoints

- `GET /api/person-tickets/?ticket_number=XXX` - Buscar ticket
- `PATCH /api/person-tickets/{id}/` - Actualizar estado del ticket

## Ejecutar

```bash
flutter pub get
flutter run
```

## Compilar APK

```bash
flutter build apk --release
```
