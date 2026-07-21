from flask import Flask, request, redirect
import mysql.connector
import os
from html import escape

app = Flask(__name__)

DB_CONFIG = {
    'host': os.environ.get('DB_HOST'),
    'port': int(os.environ.get('DB_PORT', 3306)),
    'user': os.environ.get('DB_USER'),
    'password': os.environ.get('DB_PASS'),
    'database': os.environ.get('DB_NAME'),
}

REQUIRED_ENV = ['DB_HOST', 'DB_USER', 'DB_PASS', 'DB_NAME']
missing = [k for k in REQUIRED_ENV if not os.environ.get(k)]
if missing:
    raise SystemExit(f"Missing env vars: {', '.join(missing)}")

def db():
    return mysql.connector.connect(**DB_CONFIG)

HTML = '''<!DOCTYPE html>
<html>
<head><title>Bladee Board</title>
<style>
body { font-family: sans-serif; max-width: 600px; margin: auto; padding: 20px; background: #0d0d0d; color: #eee; text-align: center; }
h1 { color: #ff66c4; }
img { width: 200px; border-radius: 10px; }
form { background: #1a1a1a; padding: 15px; border-radius: 8px; }
input, textarea { width: 100%; padding: 8px; margin: 5px 0; background: #2a2a2a; color: #eee; border: 1px solid #444; }
input[type=submit] { background: #ff66c4; color: #000; font-weight: bold; border: none; cursor: pointer; }
table { width: 100%; border-collapse: collapse; margin-top: 15px; }
td, th { border: 1px solid #333; padding: 8px; }
a { color: #ff66c4; }
</style></head>
<body>
<h1>Bladee Board</h1>
<img src="https://upload.wikimedia.org/wikipedia/en/8/8c/Bladee_-_Icedancer_cover.jpg">
<form action="/create" method=post>
<input name=name placeholder="Name" required>
<textarea name=message placeholder="Message" required></textarea>
<input type=submit value="Post">
</form>
<table><tr><th>Name</th><th>Message</th><th>Actions</th></tr>
%s
</table>
</body></html>'''

@app.route('/')
def index():
    try:
        conn = db()
        cur = conn.cursor()
        cur.execute("SELECT id, name, message FROM messages ORDER BY created_at DESC")
        rows = ''.join(
            f"<tr><td>{escape(str(r[1]))}</td><td>{escape(str(r[2]))}</td>"
            f"<td><a href='/edit/{r[0]}'>Edit</a> "
            f"<form action='/delete/{r[0]}' method=post style='display:inline'>"
            f"<input type=submit value=Delete style='background:none;border:none;color:#ff66c4;cursor:pointer;text-decoration:underline;padding:0'></form></td></tr>"
            for r in cur.fetchall()
        ) or "<tr><td colspan=3>No messages</td></tr>"
        conn.close()
        return HTML % rows
    except mysql.connector.Error as e:
        return f"<h1>DB Error</h1><p>{escape(str(e))}</p>", 500

@app.route('/create', methods=['POST'])
def create():
    try:
        conn = db()
        cur = conn.cursor()
        cur.execute("INSERT INTO messages (name, message) VALUES (%s, %s)",
                    (request.form['name'], request.form['message']))
        conn.commit()
        conn.close()
        return redirect('/')
    except mysql.connector.Error as e:
        return f"<h1>DB Error</h1><p>{escape(str(e))}</p>", 500

@app.route('/edit/<int:id>', methods=['GET', 'POST'])
def edit(id):
    try:
        conn = db()
        cur = conn.cursor()
        if request.method == 'POST':
            cur.execute("UPDATE messages SET name=%s, message=%s WHERE id=%s",
                        (request.form['name'], request.form['message'], id))
            conn.commit()
            conn.close()
            return redirect('/')
        cur.execute("SELECT name, message FROM messages WHERE id=%s", (id,))
        r = cur.fetchone()
        conn.close()
        if not r:
            return "<h1>Not Found</h1>", 404
        return f'''<form action="/edit/{id}" method=post style="max-width:400px;margin:50px auto;background:#1a1a1a;padding:15px;border-radius:8px">
<input name=name value="{escape(r[0])}" required>
<textarea name=message required>{escape(r[1])}</textarea>
<input type=submit value="Update">
<a href="/" style="display:block;margin-top:10px">Back</a>
</form>'''
    except mysql.connector.Error as e:
        return f"<h1>DB Error</h1><p>{escape(str(e))}</p>", 500

@app.route('/delete/<int:id>', methods=['POST'])
def delete(id):
    try:
        conn = db()
        cur = conn.cursor()
        cur.execute("DELETE FROM messages WHERE id=%s", (id,))
        conn.commit()
        conn.close()
        return redirect('/')
    except mysql.connector.Error as e:
        return f"<h1>DB Error</h1><p>{escape(str(e))}</p>", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
