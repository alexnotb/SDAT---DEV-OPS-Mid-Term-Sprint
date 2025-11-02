package com.example.flightcli;

import java.util.Scanner;

import com.example.flightcli.cli.FlightCli;
import com.example.flightcli.http.JavaHttpRequester;
import com.example.flightcli.service.FlightApiClient;

// CLI lead: Oleksii Bezkibalnyi
public class FlightCliApplication {

    public static void main(String[] args) {
        String baseUrl = args.length > 0 ? args[0] : "http://localhost:8080";
        FlightApiClient client = new FlightApiClient(baseUrl, new JavaHttpRequester());
        FlightCli cli = new FlightCli(client, new Scanner(System.in), System.out);
        cli.run();
    }
}
