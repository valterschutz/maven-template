Configures a Maven project with
- A raylib game skeleton split into `model`, `view` and `controller` packages
- The Maven wrapper (`mvnw`), so only a JDK needs to be installed
- An executable jar file including all dependencies (uber jar)
- The `exec:java` goal
- Testing with JUnit
- Automatic formatting with google-java-format on every build
- raylib dependency

The generated project has its own README explaining how to run it and the MVC rules.

## Creating a new project

This repo is a [Copier](https://copier.readthedocs.io/) template. You need Copier 9.10.3 or later, e.g. installed with `pipx install copier` or `uv tool install copier`.

1. Generate the project into a new directory:
   ```
   copier copy gh:valterschutz/maven-template <folder-name>
   ```
   replacing `<folder-name>` with the folder you want to create. Copier uses the latest tagged version of the template. Use `--vcs-ref <tag>` to pick another version.
2. Answer the prompts. Every prompt has a default, so you can press Enter through all of them (or pass `--defaults`) for a quick test project:
   - `project_name`: human-readable name, spaces allowed (default `My Project`).
   - `group_id`: reverse domain notation, e.g. `org.codehaus.mojo` (default `com.example`).
   - `artifact_id`: dash-separated, e.g. `exec-maven-plugin`. The base package is `<group_id>.<artifact_id>` with dashes replaced by underscores (default `my-project`).
   - `main_class`: name of the main class (default `Main`).
   - `java_version`: Java version to compile for (default `21`).

### Without Copier

If you can't run Copier, e.g. on a locked-down Windows machine, you can fill in the template by hand. You won't be able to pull in template updates later.

1. Download the repo (**Code → Download ZIP** on GitHub, or `git clone`) and copy the contents of `template/`, including hidden files such as `.mvn` and `.gitignore`, into your new project folder. Leave out the `.copier` folder.
2. Remove the `.jinja` suffix from every file name, e.g. `pom.xml.jinja` → `pom.xml`.
3. In both `src/main/java` and `src/test/java`, replace the `{{package_dir}}` folder with nested folders for your package, keeping its contents: the group ID split on dots, then the artifact ID with dashes replaced by underscores. For group ID `com.example` and artifact ID `my-game` that is `com/example/my_game`.
4. Rename `{{main_class}}.java` to use your main class name, e.g. `Main.java`.
5. Find and replace across all files (most editors can do this for a whole folder):

   | Placeholder | Replace with | Example |
   | --- | --- | --- |
   | `{{artifact_id\|replace('-','_')}}` | artifact ID with dashes replaced by underscores | `my_game` |
   | `{{artifact_id}}` | artifact ID | `my-game` |
   | `{{group_id}}` | group ID | `com.example` |
   | `{{project_name}}` | project name | `My Game` |
   | `{{main_class}}` | main class name | `Main` |
   | `{{java_version}}` | Java version | `21` |
   | `{{package_dir}}` | package folder path | `com/example/my_game` |

6. `View.java` and `ModelTest.java` build part of their imports in a `{% for %}` loop, because the correct order depends on your package name. Replace everything from the `{#` comment line to `{% endfor %}` with one `import <name>;` line per name in the list, using your package in place of `pkg ~ '...'`, e.g. `import com.example.my_game.model.Model;`. The order doesn't matter: the build formats the files and sorts the imports.
7. Search for `{{` and `{%` to check that nothing is left, then run `./mvnw verify` (`mvnw.cmd verify` on Windows).

### Updating

Your answers are stored in `.copier/maven-template-answers.yml`. To pull in later versions of the template, commit your work and run:
```
copier update --answers-file .copier/maven-template-answers.yml
```

## Running

On Windows, use `mvnw.cmd` instead of `./mvnw`.

**Run directly via Maven** (recompiles only changed files):
```
./mvnw compile exec:java
```

**Build and run the uber jar:**
```
./mvnw package
java -jar target/<artifact_id>-1.0-SNAPSHOT.jar
```

For NixOS-specific setup, see [docs/nixos.md](docs/nixos.md).

## Testing

```
./mvnw test
```

Every build first formats all Java files with google-java-format.
