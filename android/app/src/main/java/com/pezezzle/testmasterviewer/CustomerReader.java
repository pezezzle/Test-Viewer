package com.pezezzle.testmasterviewer;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.util.HashSet;
import java.util.Set;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/** Reads only the customer identifiers and names from the same read-only database snapshot. */
public final class CustomerReader {
    private CustomerReader() { }

    public static JSONArray read(SQLiteDatabase database) throws JSONException {
        JSONArray customers = new JSONArray();
        Set<String> columns = new HashSet<String>();
        try (Cursor schema = database.rawQuery("PRAGMA table_info(tblCustomer)", null)) {
            while (schema.moveToNext()) columns.add(schema.getString(1));
        }
        // Device-only databases remain usable; the interface can fall back to the customer number.
        if (!columns.contains("CustomerNumber")) return customers;
        String sql = columns.contains("Name") ? "SELECT \"CustomerNumber\", \"Name\" FROM \"tblCustomer\"" : "SELECT \"CustomerNumber\", NULL AS \"Name\" FROM \"tblCustomer\"";
        try (Cursor cursor = database.rawQuery(sql, null)) {
            while (cursor.moveToNext()) {
                JSONObject customer = new JSONObject();
                customer.put("CustomerNumber", cursor.isNull(0) ? JSONObject.NULL : cursor.getString(0));
                customer.put("Name", cursor.isNull(1) ? JSONObject.NULL : cursor.getString(1));
                customers.put(customer);
            }
        }
        return customers;
    }
}
