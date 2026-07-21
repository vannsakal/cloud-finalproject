from flask import Flask, request, redirect, render_template
import mysql.connector
import os

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

@app.route('/')
def index():
    try:
        conn = db()
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT id, name, message FROM messages ORDER BY created_at DESC")
        rows = cur.fetchall()
        conn.close()
        return render_template('index.html', rows=rows)
    except mysql.connector.Error as e:
        return f"<h1>DB Error</h1><p>{e}</p>", 500

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
        return f"<h1>DB Error</h1><p>{e}</p>", 500

@app.route('/edit/<int:id>', methods=['GET', 'POST'])
def edit(id):
    try:
        conn = db()
        cur = conn.cursor(dictionary=True)
        if request.method == 'POST':
            cur.execute("UPDATE messages SET name=%s, message=%s WHERE id=%s",
                        (request.form['name'], request.form['message'], id))
            conn.commit()
            conn.close()
            return redirect('/')
        cur.execute("SELECT name, message FROM messages WHERE id=%s", (id,))
        row = cur.fetchone()
        conn.close()
        if not row:
            return "<h1>Not Found</h1>", 404
        return render_template('edit.html', id=id, name=row['name'], message=row['message'])
    except mysql.connector.Error as e:
        return f"<h1>DB Error</h1><p>{e}</p>", 500

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
        return f"<h1>DB Error</h1><p>{e}</p>", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
