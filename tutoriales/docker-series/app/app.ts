import express, { Request, Response } from 'express';
import { json, urlencoded } from 'body-parser';
import { createConnection, MysqlError, PoolConnection, FieldInfo } from 'mysql';
import { config } from 'dotenv';

config();

export const app = express();

app.use(json());
app.use(urlencoded({ extended: true }));

interface User {
  id: number;
  name: string;
  email: string;
}

// Configure database connection

const db = createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});


// Connect to the database
db.connect((err: MysqlError | null) => {
  if (err) throw err;
  console.log('Connected to the database');
});

app.get('/status', (req: Request, res: Response) => {
  res.sendStatus(200);
});

// Dummy endpoint that gets all data from a 'users' table
app.get('/users', (req: Request, res: Response) => {
  db.query('SELECT * FROM users', (err: MysqlError | null, results: User[], fields: FieldInfo[] | undefined) => {
    if (err) throw err;
    res.json(results);
  });
});

// Dummy endpoint that gets a user by id from a 'users' table
app.get('/users/:id', (req: Request, res: Response) => {
  db.query('SELECT * FROM users WHERE id = ?', [req.params.id], (err: MysqlError | null, results: User[], fields: FieldInfo[] | undefined) => {
    if (err) throw err;
    res.json(results[0]);
  });
});

// Dummy endpoint that inserts a user into a 'users' table
app.post('/users', (req: Request, res: Response) => {
  const user: User = req.body;
  db.query('INSERT INTO users SET ?', user, (err: MysqlError | null, results: any) => {
    if (err) throw err;
    res.json(results);
  });
});


// Start the server
const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
