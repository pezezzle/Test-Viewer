# Synthetic sample data

The welcome screen provides **Try with sample data**. Demo mode is clearly marked and never mixes its data with a selected database.

To test Android or iOS folder selection, create an additional SQLite file containing only synthetic data:

```sh
python tool/create_demo_database.py example/demo.sqlite3
```

Copy this file into a shared folder on the test device. Select that folder and `demo.sqlite3` in the app. Git ignores the generated file, and the generator never overwrites an existing file.

Every person, customer, manufacturer, and device in the sample is fictional. The data is not an inspection report and must not be used to assess device safety.
