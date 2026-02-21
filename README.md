Configures a Maven project with
- An executable jar file including all dependencies (uber jar)
- The `exec:java` goal
- Testing with JUnit
- raylib dependency

## Running

**Run directly via Maven** (recompiles only changed files):
```
mvn compile exec:java
```

**Build and run the uber jar:**
```
mvn package
java -jar target/<artifact_id>-1.0-SNAPSHOT.jar
```

## Testing

```
mvn test
```
