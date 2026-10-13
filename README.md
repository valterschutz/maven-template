Configures a Maven project with
- An executable jar file including all dependencies (uber jar)
- The `exec:java` goal
- Testing with JUnit
- raylib dependency

## Creating a new project

This repo is a [Copier](https://copier.readthedocs.io/) template. You need Copier 9.10.3 or later, e.g. installed with `pipx install copier` or `uv tool install copier`.

1. Generate the project into a new directory:
   ```
   copier copy gh:valterschutz/maven-template my-project
   ```
   Copier uses the latest tagged version of the template. Use `--vcs-ref <tag>` to pick another version.
2. Answer the prompts:
   - `project_name`: human-readable name, spaces allowed.
   - `group_id`: reverse domain notation, e.g. `org.codehaus.mojo`.
   - `artifact_id`: dash-separated, e.g. `exec-maven-plugin`. The base package is `<group_id>.<artifact_id>` with dashes replaced by underscores.
   - `main_class`: name of the main class (default `Main`).
   - `java_version`: Java version to compile for (default `21`).

### Without Copier

If you can't run Copier, e.g. on a locked-down Windows machine, you can fill in the template by hand. You won't be able to pull in template updates later.

1. Download the repo (**Code → Download ZIP** on GitHub, or `git clone`) and copy the contents of `template/` into your new project folder. Leave out the `.copier` folder.
2. Remove the `.jinja` suffix from every file name, e.g. `pom.xml.jinja` → `pom.xml`.
3. In both `src/main/java` and `src/test/java`, replace the `{{package_dir}}` folder with nested folders for your package: the group ID split on dots, then the artifact ID with dashes replaced by underscores. For group ID `com.example` and artifact ID `my-game` that is `com/example/my_game`.
4. Rename `{{main_class}}.java` and `{{main_class}}Test.java` to use your main class name, e.g. `Main.java` and `MainTest.java`.
5. Find and replace across all files (most editors can do this for a whole folder):

   | Placeholder | Replace with | Example |
   | --- | --- | --- |
   | `{{artifact_id\|replace('-','_')}}` | artifact ID with dashes replaced by underscores | `my_game` |
   | `{{artifact_id}}` | artifact ID | `my-game` |
   | `{{group_id}}` | group ID | `com.example` |
   | `{{project_name}}` | project name | `My Game` |
   | `{{main_class}}` | main class name | `Main` |
   | `{{java_version}}` | Java version | `21` |

6. Search for `{{` to check that nothing is left, then run `mvn test`.

### Updating

Your answers are stored in `.copier/maven-template-answers.yml`. To pull in later versions of the template, commit your work and run:
```
copier update --answers-file .copier/maven-template-answers.yml
```

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

For NixOS-specific setup, see [docs/nixos.md](docs/nixos.md).

## Testing

```
mvn test
```
