#!/bin/bash

# Directory per il file decifrato di dislocker
DISLOCKER_MOUNT_DIR="/mnt/dislocker_mount"

# Directory per montare la partizione decifrata
BITLOCKER_MOUNT_DIR="/mnt/bitlocker_mount"

# Recovery keys hardcoded
RECOVERY_KEY_1="097471-239811-382591-296252-034991-220143-267597-017897"
RECOVERY_KEY_2="269610-395901-307868-117524-446336-318538-203709-610610"

# Funzione per installare i pacchetti necessari
install_packages() {
    echo "Installazione dei pacchetti necessari..."
    sudo apt-get update
    sudo apt-get install -y dislocker chntpw
    if [ $? -ne 0 ]; then
        echo "Errore durante l'installazione dei pacchetti."
        exit 1
    fi
    echo "Pacchetti installati con successo."
}

# Funzione per gestire le directory di montaggio
setup_mount_dirs() {
    # Crea o gestisci la directory per dislocker
    if [ -d "$DISLOCKER_MOUNT_DIR" ]; then
        echo "La directory $DISLOCKER_MOUNT_DIR esiste già."
        echo "Vuoi sovrascriverla? (s/n):"
        read -r response
        if [[ "$response" =~ ^[sS]$ ]]; then
            echo "Rimozione della directory esistente..."
            sudo rm -rf "$DISLOCKER_MOUNT_DIR"
            sudo mkdir -p "$DISLOCKER_MOUNT_DIR"
            echo "Directory $DISLOCKER_MOUNT_DIR creata."
        else
            echo "Inserisci un'altra directory per dislocker:"
            read -r DISLOCKER_MOUNT_DIR
            sudo mkdir -p "$DISLOCKER_MOUNT_DIR"
            echo "Directory $DISLOCKER_MOUNT_DIR creata."
        fi
    else
        echo "Creazione della directory $DISLOCKER_MOUNT_DIR..."
        sudo mkdir -p "$DISLOCKER_MOUNT_DIR"
        echo "Directory $DISLOCKER_MOUNT_DIR creata."
    fi

    # Crea o gestisci la directory per montare la partizione
    if [ -d "$BITLOCKER_MOUNT_DIR" ]; then
        echo "La directory $BITLOCKER_MOUNT_DIR esiste già."
        echo "Vuoi sovrascriverla? (s/n):"
        read -r response
        if [[ "$response" =~ ^[sS]$ ]]; then
            echo "Rimozione della directory esistente..."
            sudo rm -rf "$BITLOCKER_MOUNT_DIR"
            sudo mkdir -p "$BITLOCKER_MOUNT_DIR"
            echo "Directory $BITLOCKER_MOUNT_DIR creata."
        else
            echo "Inserisci un'altra directory per montare la partizione:"
            read -r BITLOCKER_MOUNT_DIR
            sudo mkdir -p "$BITLOCKER_MOUNT_DIR"
            echo "Directory $BITLOCKER_MOUNT_DIR creata."
        fi
    else
        echo "Creazione della directory $BITLOCKER_MOUNT_DIR..."
        sudo mkdir -p "$BITLOCKER_MOUNT_DIR"
        echo "Directory $BITLOCKER_MOUNT_DIR creata."
    fi
}

# Funzione per mostrare le partizioni disponibili
show_partitions() {
    echo "Elenco delle partizioni disponibili:"
    lsblk
    echo ""
}

# Funzione per montare la partizione BitLocker
mount_bitlocker() {
    show_partitions
    echo "Inserisci il percorso della partizione BitLocker (es. /dev/sdb1):"
    read -r partition

    # Chiedi all'utente quale recovery key usare
    echo "Scegli la recovery key da utilizzare:"
    echo "1. $RECOVERY_KEY_1"
    echo "2. $RECOVERY_KEY_2"
    read -r key_choice

    case $key_choice in
        1)
            recovery_key="$RECOVERY_KEY_1"
            ;;
        2)
            recovery_key="$RECOVERY_KEY_2"
            ;;
        *)
            echo "Scelta non valida. Uscita."
            exit 1
            ;;
    esac

    # Montaggio della partizione BitLocker con la recovery key
    echo "Montaggio della partizione BitLocker con la recovery key..."
    sudo dislocker -V "$partition" -p$recovery_key -- "$DISLOCKER_MOUNT_DIR"
    if [ $? -ne 0 ]; then
        echo "Errore durante il montaggio della partizione BitLocker."
        exit 1
    fi

    # Montaggio del filesystem decifrato
    echo "Montaggio del filesystem decifrato in $BITLOCKER_MOUNT_DIR..."
    sudo mount -o loop "$DISLOCKER_MOUNT_DIR/dislocker-file" "$BITLOCKER_MOUNT_DIR"
    if [ $? -ne 0 ]; then
        echo "Errore durante il montaggio del filesystem decifrato."
        exit 1
    fi

    echo "Partizione BitLocker montata con successo in $BITLOCKER_MOUNT_DIR."
}

# Funzione per aprire il file SAM
open_sam() {
    sam_file="$BITLOCKER_MOUNT_DIR/Windows/System32/config/SAM"
    if [ -f "$sam_file" ]; then
        echo "Apertura del file SAM con chntpw..."
        sudo chntpw -l "$sam_file"
    else
        echo "File SAM non trovato in $sam_file."
        exit 1
    fi
}

# Main script
install_packages
setup_mount_dirs
mount_bitlocker
open_sam