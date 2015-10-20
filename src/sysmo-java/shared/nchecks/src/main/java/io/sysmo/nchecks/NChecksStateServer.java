/*
 * Sysmo NMS Network Management and Monitoring solution (http://www.sysmo.io)
 *
 * Copyright (c) 2012-2015 Sebastien Serre <ssbx@sysmo.io>
 *
 * This file is part of Sysmo NMS.
 *
 * Sysmo NMS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Sysmo NMS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Sysmo.  If not, see <http://www.gnu.org/licenses/>.
 */

package io.sysmo.nchecks;

import com.sleepycat.je.Database;
import com.sleepycat.je.DatabaseConfig;
import com.sleepycat.je.DatabaseEntry;
import com.sleepycat.je.Environment;
import com.sleepycat.je.EnvironmentConfig;
import com.sleepycat.je.LockMode;
import com.sleepycat.je.OperationStatus;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;

import java.net.ServerSocket;
import java.net.Socket;

import java.nio.file.Paths;

/**
 * Created by seb on 18/10/15.
 * TODO Provide berkley db store for NChecks modules state.
 */
public class NChecksStateServer implements Runnable {
    private static NChecksStateServer instance;
    private static final String DB_NAME = "NCHECKS_STATES";
    private Database db;
    private Environment env;
    private Logger logger;
    private final Object lock = new Object();

    public void stop() {
        synchronized (this.lock) {
            this.lock.notify();
        }
    }

    public static synchronized void getState(String key) {
        synchronized (NChecksStateServer.instance.lock) {
        }
    }

    public static synchronized void setState(String key, String data) {
        synchronized (NChecksStateServer.instance.lock) {
        }
    }
    public static synchronized NChecksStateServer getInstance(String dataDir) {
        if (NChecksStateServer.instance == null) {
            NChecksStateServer.instance = new NChecksStateServer(dataDir);
        }
        return NChecksStateServer.instance;
    }

    private NChecksStateServer(String dataDir) {

        this.logger = LoggerFactory.getLogger(this.getClass());

        // init db
        String home = Paths.get(dataDir, "states").toString();
        EnvironmentConfig envConfig = new EnvironmentConfig();
        envConfig.setAllowCreate(true);
        this.env = new Environment(new File(home), envConfig);

        DatabaseConfig dbConfig = new DatabaseConfig();
        dbConfig.setAllowCreate(true);
        this.db = this.env.openDatabase(null, NChecksStateServer.DB_NAME, dbConfig);
        this.logger.info("database ok");
    }

    @Override
    public void run() {
        // populate test
        String aKey = "keyjojo";
        String aData = "datajojoqsdfqsdfj";
        this.logger.info("will put data in db");
        try {
            DatabaseEntry theKey = new DatabaseEntry(aKey.getBytes("UTF-8"));
            DatabaseEntry theData = new DatabaseEntry(aData.getBytes("UTF-8"));
            this.db.put(null, theKey, theData);
            this.logger.info("data success");

            this.logger.info("will get data");

            DatabaseEntry theKey2 = new DatabaseEntry("keyjojo".getBytes("UTF-8"));
            DatabaseEntry theData2 = new DatabaseEntry();
            if (this.db.get(null, theKey2, theData2, LockMode.DEFAULT) ==
                    OperationStatus.SUCCESS) {
                byte[] originalData = theData.getData();
                String strData = new String(originalData, "UTF-8");
                this.logger.info("for key: 'key' found data: " + strData);
            } else {
                this.logger.info("for key: 'key' found no data");
            }
        } catch (UnsupportedEncodingException e) {
            this.logger.info("encoding exception");
            e.printStackTrace();
        }

        try {
            synchronized (this.lock) {
                this.lock.wait();
            }
        } catch (InterruptedException e) {
            this.logger.error(e.getMessage(), e);
            // ignore
        } finally {
            this.db.close();
            this.env.close();
            this.logger.info("end run");
        }
    }


    void other() {
        // server loop
        ServerSocket server;
        try {
            server = new ServerSocket(8867);
        } catch (IOException e) {
            // ignore
            return;
        }

        while (true) try {

            Socket client = server.accept();
            Runnable clientRunnable = new StateStoreClient(client);
            Thread clientThread = new Thread(clientRunnable);
            clientThread.start();

        } catch (Exception|Error e) {
            break;
        }

        // close
    }

    // utility classes
    static class StateStoreClient implements Runnable {

        StateStoreClient(Socket client) {

        }

        @Override
        public void run() {
            // handle client socket read write

        }
    }
}
