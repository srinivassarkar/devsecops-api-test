const request = require("supertest");
const app = require("./app");

let server;
beforeAll(() => {
  server = app.listen(4000); // test port
});
afterAll((done) => {
  server.close(done);
});

describe("API Endpoints", () => {
  describe("GET /health", () => {
    it("should return health status", async () => {
      const response = await request(app).get("/health").expect(200);

      expect(response.body).toHaveProperty("status", "healthy");
      expect(response.body).toHaveProperty("timestamp");
      expect(response.body).toHaveProperty("version");
    });
  });

  describe("GET /api/users", () => {
    it("should return list of users", async () => {
      const response = await request(app).get("/api/users").expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
    });
  });

  describe("POST /api/users", () => {
    it("should create a new user with valid data", async () => {
      const userData = {
        name: "Test User",
        email: "test@example.com",
      };

      const response = await request(app)
        .post("/api/users")
        .send(userData)
        .expect(201);

      expect(response.body).toHaveProperty("id");
      expect(response.body).toHaveProperty("name", userData.name);
      expect(response.body).toHaveProperty("email", userData.email);
    });

    it("should return 400 for missing name", async () => {
      const userData = {
        email: "test@example.com",
      };

      await request(app).post("/api/users").send(userData).expect(400);
    });

    it("should return 400 for invalid email", async () => {
      const userData = {
        name: "Test User",
        email: "invalid-email",
      };

      await request(app).post("/api/users").send(userData).expect(400);
    });
  });

  describe("GET /api/users/:id", () => {
    it("should return user by ID", async () => {
      const response = await request(app).get("/api/users/1").expect(200);

      expect(response.body).toHaveProperty("id", 1);
      expect(response.body).toHaveProperty("name");
      expect(response.body).toHaveProperty("email");
    });

    it("should return 400 for invalid ID", async () => {
      await request(app).get("/api/users/invalid").expect(400);
    });
  });

  describe("404 handler", () => {
    it("should return 404 for non-existent routes", async () => {
      await request(app).get("/non-existent-route").expect(404);
    });
  });
});
