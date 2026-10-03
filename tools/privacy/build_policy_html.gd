extends SceneTree
## Dev-only (tools/ is export-excluded). Generates docs/privacy-policy/index.html from the canonical
## PrivacyPolicyText so the public web copy and the in-game policy cannot drift:
##   godot --headless --path . --script res://tools/privacy/build_policy_html.gd
## test_privacy_policy.gd compares build_html() against the committed file.

const Policy := preload("res://scripts/ui/privacy_policy_text.gd")
const OUT := "res://docs/privacy-policy/index.html"


static func _esc(t: String) -> String:
	return t.xml_escape()


static func build_html() -> String:
	var body := ""
	for section: Dictionary in Policy.SECTIONS:
		body += "      <section>\n        <h2>%s</h2>\n" % _esc(section["heading"])
		for block: Variant in section["blocks"]:
			if block is String:
				body += "        <p>%s</p>\n" % _esc(block)
			elif block is Dictionary:
				body += "        <h3>%s</h3>\n" % _esc(block["sub"])
			elif block is Array:
				body += "        <ul>\n"
				for item: String in block:
					body += "          <li>%s</li>\n" % _esc(item)
				body += "        </ul>\n"
		body += "      </section>\n"
	return HTML_TEMPLATE.replace("{TITLE}", _esc(Policy.GAME + " " + Policy.TITLE)) \
		.replace("{GAME}", _esc(Policy.GAME)) \
		.replace("{EFFECTIVE}", _esc(Policy.EFFECTIVE_DATE)) \
		.replace("{UPDATED}", _esc(Policy.LAST_UPDATED)) \
		.replace("{PUBLISHER}", _esc(Policy.PUBLISHER)) \
		.replace("{DEVELOPER}", _esc(Policy.DEVELOPER)) \
		.replace("{EMAIL}", _esc(Policy.EMAIL)) \
		.replace("{BODY}", body)


func _init() -> void:
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f == null:
		push_error("cannot write " + OUT)
		quit(1)
		return
	f.store_string(build_html())
	f.close()
	print("wrote ", OUT)
	quit()


const HTML_TEMPLATE := """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="dark">
  <title>{TITLE}</title>
  <meta name="description" content="Privacy Policy for {GAME}, a laser-reflection puzzle game by {PUBLISHER}.">
  <style>
    :root { --bg:#050b17; --card:#0c1a2e; --line:#1d4a6b; --cyan:#4fd8ff; --text:#e6f1fa; --dim:#9db4c7; }
    * { box-sizing: border-box; }
    html { -webkit-text-size-adjust: 100%; }
    body { margin:0; background:radial-gradient(1200px 600px at 50% -10%, #0e2a47 0%, var(--bg) 70%) fixed; color:var(--text);
      font:18px/1.65 system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif; }
    main { max-width:760px; margin:0 auto; padding:32px 16px 64px; }
    header { text-align:center; margin-bottom:28px; }
    .brand { letter-spacing:.32em; color:var(--cyan); font-weight:700; font-size:15px; text-transform:uppercase; }
    h1 { margin:.3em 0 .4em; font-size:clamp(28px,6vw,40px); letter-spacing:.04em; text-transform:uppercase; }
    .meta { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:16px 20px; color:var(--dim); font-size:16px; }
    .meta strong { color:var(--text); font-weight:600; }
    .meta p { margin:.2em 0; }
    section { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:8px 20px 14px; margin:20px 0; }
    h2 { color:var(--cyan); font-size:22px; margin:.9em 0 .4em; padding-bottom:.35em; border-bottom:1px solid var(--line); }
    h3 { color:var(--cyan); font-size:18px; margin:1.2em 0 .2em; }
    p { margin:.7em 0; overflow-wrap:anywhere; }
    ul { margin:.6em 0; padding-left:1.3em; }
    li { margin:.45em 0; overflow-wrap:anywhere; }
    a { color:var(--cyan); }
    footer { text-align:center; color:var(--dim); font-size:14px; margin-top:32px; }
  </style>
</head>
<body>
  <main>
    <header>
      <div class="brand">{GAME}</div>
      <h1>Privacy Policy</h1>
      <div class="meta">
        <p><strong>Effective date:</strong> {EFFECTIVE}</p>
        <p><strong>Last updated:</strong> {UPDATED}</p>
        <p><strong>Publisher:</strong> {PUBLISHER}</p>
        <p><strong>Developer:</strong> {DEVELOPER}</p>
        <p><strong>Email:</strong> <a href="mailto:{EMAIL}">{EMAIL}</a></p>
      </div>
    </header>
{BODY}    <footer>&copy; {PUBLISHER}. {GAME} is developed by {DEVELOPER}.</footer>
  </main>
</body>
</html>
"""
