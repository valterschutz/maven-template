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

If you can't install Copier, use the `new-project.sh` script in this repo instead. It asks the same questions and creates the same project. It only needs bash, so on Windows run it in Git Bash, which comes with [Git for Windows](https://git-scm.com/downloads/win).

1. Download the repo: `git clone https://github.com/valterschutz/maven-template.git`, or **Code → Download ZIP** on GitHub and unzip it.
2. Open a terminal (Git Bash on Windows) in the downloaded folder and run:
   ```
   bash new-project.sh <folder-name>
   ```
   replacing `<folder-name>` with the folder you want to create, e.g. `../my-game`. Answer the prompts as described above, or add `--defaults` to skip them. If you leave out `<folder-name>`, the script asks for it.

The project gets the same answers file as with Copier, so you can use `copier update` later if you install Copier. This only works if you cloned the repo with Git: a ZIP download doesn't record which template version you used.

### Updating

Your answers are stored in `.copier/maven-template-answers.yml`. To pull in later versions of the template, commit your work and run:
```
copier update --answers-file .copier/maven-template-answers.yml
```

## Running

The commands use the Maven wrapper (`./mvnw`) instead of `mvn`. It downloads the Maven version pinned in `.mvn/wrapper/maven-wrapper.properties` on first use, so you only need a JDK and everyone builds with the same Maven version. On Windows, use `mvnw.cmd` instead of `./mvnw`.

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

## Developing the template

`new-project.sh` reimplements the parts of Copier the template uses, so it has to be kept in sync with `copier.yml` and the `.jinja` files. The script fails on Jinja syntax it doesn't understand. After changing the template, run:
```
tests/compare-with-copier.sh
```
It needs Copier, and checks that the script and Copier create the same files for several sets of answers.
