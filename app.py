import flask


app = flask.Flask(__name__)


@app.route('/')
def home():
    return 'Hello, World!'


@app.route("/version")
def version():
    return "Version 1.0"


@app.route("/docs")
def docs():
    return "Documentation Page"


@app.route("/sales")
def sales():
    return "Sales Page2ssss"


@app.route("/products")
def products():
    return "Products Page"

if __name__ == '__main__':
    app.run(debug=True)
