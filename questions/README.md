# Questions folder

Drop your question files in **this folder**. Nothing here is uploaded anywhere — the
Brain Brawl console reads the files straight off this laptop.

## How to load them

1. Open `brainbrawl-hud.html` (double-click it).
2. In the **Questions folder** card, click **Load questions folder**.
3. Pick this `questions` folder. Every file inside is read and parsed in one go.
4. The card shows how many questions came out of each file, and you can step through
   them with **Previous** / **Next** (the projector's "Question" number follows along).

The parsed questions are remembered on this laptop, so next time you open the file you
do not need to pick the folder again — only when you add or change files.

You can also drag a single file (or the whole folder) onto the dashed box in that card,
or use **Choose files** to pick a few at once.

## What it understands

| File | Notes |
| --- | --- |
| `.tpqx` | Tried as a zip or gzip container first; every text file inside is parsed. If your `.tpqx` is not one of those, see below. |
| `.json` | A list of questions, or `{ "questions": [...] }`. Keys: `q`/`question`/`prompt`, `a`/`answer`, `b`/`bonus`, `h`/`hint`, `p`/`points`, `d`/`difficulty`. |
| `.txt`, `.md` | The `Q:` / `A:` / `B:` sheet format below, or a numbered study guide. |
| `.csv`, `.tsv` | Columns `question,answer,bonus` (a header row is optional). |
| `.zip`, `.gz` | Opened up, and the text files inside are parsed. |

## Sheet format

```
# Naval Science 2 - Chapter 4
Q: What does SONAR stand for?
A: Sound Navigation and Ranging
B: What does RADAR stand for?
H: It starts with SOund
P: 15
D: 2

Q: Who is the Secretary of the Navy?
A: ...
```

`Q:` and `A:` are the only required bits. `B:` is the bonus question, `H:` a hint
(repeatable), `P:` points, `D:` difficulty 1-3, and `#` sets the pack name.

A numbered study guide also works — every numbered line ending in `?` becomes a
question and the next line becomes its answer:

```
1. What is the cadet chain of command?
CO, XO, then the department chiefs.
2. What does NJROTC stand for?
Naval Junior Reserve Officers' Training Corps
```

## If nothing loads from the .tpqx

That file is not a zip, gzip, JSON or text file this page can read — some quiz
programs use their own binary format. Two ways round it:

- Open the `.tpqx` in **7-Zip** (or rename it to `.zip` and double-click). If the
  archive opens, extract the files into this folder and load the folder again.
- Use the quiz program's **Export** option to save the questions as text, CSV or
  JSON, and drop that export in here instead.

The status line under the drop box names the file it could not read, so you can tell
which one is the problem.
