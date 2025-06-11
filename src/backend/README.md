# Backend

To run locally, cp `application.properties` to `application-local.properties` and modify the configuration to match your local deployment.

For example:

```properties
db.url=jdbc:oracle:thin:@//localhost:1521/FREEPDB1
db.username=pdbadmin
db.password=XXXXX
```

```bash
./gradlew run
```

```bash
./gradlew shadowJar
```
