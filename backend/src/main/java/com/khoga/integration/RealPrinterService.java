package com.khoga.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.OutputStream;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

@Slf4j
@Service
public class RealPrinterService implements PrinterService {

    @Value("${app.printer.host:127.0.0.1}")
    private String printerHost;

    @Value("${app.printer.port:9100}")
    private int printerPort;

    // ESC/POS commands
    private static final byte[] INIT = {0x1B, 0x40};
    private static final byte[] CUT = {0x1D, 0x56, 0x41, 0x10};

    @Override
    public void printReceipt(String content) {
        log.info("[PRINTER] Printing Receipt via TCP to {}:{}", printerHost, printerPort);
        sendToPrinter(content);
    }

    @Override
    public void printLabel(String content) {
        log.info("[PRINTER] Printing Label via TCP to {}:{}", printerHost, printerPort);
        sendToPrinter(content);
    }

    private void sendToPrinter(String text) {
        try (Socket socket = new Socket(printerHost, printerPort);
             OutputStream out = socket.getOutputStream()) {
             
            // Initialize printer
            out.write(INIT);
            
            // Print text
            out.write(text.getBytes(StandardCharsets.UTF_8));
            out.write('\n');
            out.write('\n');
            
            // Cut paper
            out.write(CUT);
            out.flush();
        } catch (Exception e) {
            log.warn("[PRINTER] Could not connect to printer at {}:{} - {}", printerHost, printerPort, e.getMessage());
        }
    }
}
