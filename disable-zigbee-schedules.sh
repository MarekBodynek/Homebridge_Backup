#!/bin/bash

# Skrypt do wyłączenia harmonogramów Zigbee i ustawienia regulatorów na tryb ręczny
# HomeKit powinien być głównym źródłem kontroli temperatury

MQTT_SERVER="localhost"
MQTT_PORT="1883"
MQTT_USER="mqtt"
MQTT_PASSWORD="mqtt"
BASE_TOPIC="zigbee2mqtt"

# Lista regulatorów kaloryferów
DEVICES=(
    "Regulator kaloryfer jadalnia"
    "Regulator kaloryfer sypialnia"
    "Regulator kaloryfer biuro"
    "Regulator kaloryfer pokój Patryka"
)

echo "==========================================="
echo "Wyłączanie harmonogramów Zigbee w regulatorach"
echo "HomeKit będzie głównym źródłem kontroli"
echo "==========================================="
echo ""

for device in "${DEVICES[@]}"; do
    echo "Konfigurowanie: $device"

    # Ustawienie trybu manual (zamiast auto, który używa harmonogramów)
    mosquitto_pub -h "$MQTT_SERVER" -p "$MQTT_PORT" \
        -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
        -t "$BASE_TOPIC/$device/set" \
        -m '{"preset":"manual"}'

    echo "  ✓ Ustawiono preset: manual"

    # Wyłączenie system_mode schedule (jeśli dostępne)
    # Niektóre urządzenia mogą wymagać ustawienia system_mode na 'heat' zamiast 'auto'
    mosquitto_pub -h "$MQTT_SERVER" -p "$MQTT_PORT" \
        -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
        -t "$BASE_TOPIC/$device/set" \
        -m '{"system_mode":"heat"}'

    echo "  ✓ Ustawiono system_mode: heat"

    echo ""
    sleep 1
done

echo "==========================================="
echo "Zakończono konfigurację"
echo "==========================================="
echo ""
echo "UWAGA: Wszystkie regulatory są teraz w trybie ręcznym."
echo "HomeKit będzie kontrolował temperaturę bez konfliktów z harmonogramami Zigbee."
echo ""
echo "Aby zweryfikować ustawienia, sprawdź:"
echo "  - Interfejs Zigbee2MQTT (http://localhost:8080)"
echo "  - Aplikację Home na iOS/macOS"
echo ""
