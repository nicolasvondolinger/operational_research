#include <iostream>
#include <fstream>
#include <iomanip>
#include <cmath>

#define _ ios_base::sync_with_stdio(0); cin.tie(0);
#define endl '\n'
#define pb push_back

typedef long long ll;

const double INF = 0x3f3f3f3f, EPS = 1e-9;

using namespace std;

template<typename T>
class Vector {
private:
    T* data;
    size_t capacity;
    size_t length;
    void resize(size_t new_capacity) {
        T* new_data = new T[new_capacity];
        for (size_t i = 0; i < length; ++i)
            new_data[i] = data[i];
        delete[] data;
        data = new_data;
        capacity = new_capacity;
    }

public:
    Vector() : capacity(4), length(0) { data = new T[capacity]; }
    Vector(size_t size, const T& value) : capacity(size), length(size) {
        data = new T[capacity];
        for (size_t i = 0; i < length; ++i) data[i] = value;
    }
    Vector(const Vector& other) : capacity(other.capacity), length(other.length) {
        data = new T[capacity];
        for (size_t i = 0; i < length; ++i) data[i] = other.data[i];
    }
    Vector& operator=(const Vector& other) {
        if (this != &other) {
            delete[] data;
            capacity = other.capacity;
            length = other.length;
            data = new T[capacity];
            for (size_t i = 0; i < length; ++i) data[i] = other.data[i];
        }
        return *this;
    }
    ~Vector() { delete[] data; }

    void push_back(const T& value) {
        if (length == capacity) resize(capacity * 2);
        data[length++] = value;
    }
    void pop_back() { if (length > 0) --length; }

    size_t size() const { return length; }
    bool empty() const { return length == 0; }

    T& operator[](size_t index) { return data[index]; }
    const T& operator[](size_t index) const { return data[index]; }

    void clear() { length = 0; }
};

static string formatDouble(double v) {
    double v3 = v >= 0 ? floor(v * 1000.0 + 0.5) / 1000.0 : ceil(v * 1000.0 - 0.5) / 1000.0;
    ll iv = (ll)v3;
    double frac = fabs(v3 - (double)iv);
    int f = (int)round(frac * 1000);
    if (f == 1000) { iv += (v3 >= 0 ? 1 : -1); f = 0; }
    string s = (v3 < 0 ? "-" : "") + to_string(llabs(iv));
    s.pb('.');
    int d1 = f/100, d2=(f/10)%10, d3=f%10;
    s.pb('0'+d1);
    s.pb('0'+d2);
    s.pb('0'+d3);
    while (s.size()>2 && s.back()=='0') s.pop_back();
    if (s.back()=='.') s.pb('0');
    return s;
}

static int n, m;
static Vector<double> c;
static Vector< Vector<double> > A_ineq;
static Vector<double> b_ineq;
static Vector<double> sol;

static Vector<int> B, N;
static Vector< Vector<double> > D;

void buildTableau() {
    int rows = A_ineq.size();
    int cols = m;
    B = Vector<int>(rows, 0);
    N = Vector<int>(cols+1, 0);
    D = Vector< Vector<double> >(rows+2, Vector<double>(cols+2, 0.0));
    for (int i = 0; i < rows; ++i)
        for (int j = 0; j < cols; ++j)
            D[i][j] = A_ineq[i][j];
    for (int i = 0; i < rows; ++i) {
        B[i] = cols + i;
        D[i][cols] = -1;
        D[i][cols+1] = b_ineq[i];
    }
    for (int j = 0; j < cols; ++j) {
        N[j] = j;
        D[rows][j] = -c[j];
    }
    N[cols] = -1;
    D[rows+1][cols] = 1;
}

void pivot(int r, int s) {
    int rows = D.size();
    int cols = D[0].size();
    double inv = 1.0 / D[r][s];
    for (int i = 0; i < rows; ++i) if (i != r)
        for (int j = 0; j < cols; ++j) if (j != s)
            D[i][j] -= D[r][j] * D[i][s] * inv;
    for (int j = 0; j < cols; ++j) if (j != s) D[r][j] *= inv;
    for (int i = 0; i < rows; ++i) if (i != r) D[i][s] *= -inv;
    D[r][s] = inv;
    swap(B[r], N[s]);
}

bool simplexPhase(int phase) {
    int rows = D.size()-2;
    int cols = D[0].size()-2;
    int x = (phase == 1 ? rows+1 : rows);
    while (true) {
        int s = -1;
        for (int j = 0; j <= cols; ++j) {
            if (phase==2 && N[j]==-1) continue;
            if (s==-1 || D[x][j] < D[x][s] || (fabs(D[x][j]-D[x][s])<EPS && N[j]<N[s]))
                s = j;
        }
        if (D[x][s] > -EPS) return true;
        int r = -1;
        for (int i = 0; i < rows; ++i) {
            if (D[i][s] > EPS) {
                if (r==-1 || D[i][cols+1]/D[i][s] < D[r][cols+1]/D[r][s] ||
                   (fabs(D[i][cols+1]/D[i][s]-D[r][cols+1]/D[r][s])<EPS && B[i]<B[r]))
                    r = i;
            }
        }
        if (r==-1) return false;
        pivot(r, s);
    }
}

double solveLP() {
    buildTableau();
    int rows = D.size()-2;
    // Phase 1
    int r = 0;
    for (int i = 1; i < rows; ++i)
        if (D[i][m+1] < D[r][m+1]) r = i;
    if (D[r][m+1] < -EPS) {
        pivot(r, m);
        if (!simplexPhase(1) || D[rows+1][m+1] < -EPS) return NAN;
        if (fabs(D[rows+1][m+1]) > EPS) return NAN;
        for (int i = 0; i < rows; ++i)
            if (B[i] == -1) {
                int s = 0;
                while (fabs(D[i][s]) < EPS) ++s;
                pivot(i, s);
                break;
            }
    }
    // Phase 2
    if (!simplexPhase(2)) return INF;
    sol = Vector<double>(m, 0.0);
    for (int i = 0; i < rows; ++i)
        if (B[i] < m) sol[B[i]] = D[i][m+1];
    return D[rows][m+1];
}

int main(int argc, char* argv[]) { _

    if (argc != 3) {
        cerr << "Uso: ./codigo entrada.txt saida.txt\n";
        return 1;
    }

    ifstream entrada(argv[1]);
    ofstream saida(argv[2]);

    if (!entrada.is_open() || !saida.is_open()) {
        cerr << "Erro ao abrir arquivos.\n";
        return 1;
    }

    entrada >> n >> m; c = Vector<double>(m, 0.0);

    for (int j = 0; j < m; ++j) entrada >> c[j];
    for (int i = 0; i < n; ++i) {
        Vector<double> a(m, 0.0);
        double bi;
        for (int j = 0; j < m; ++j) entrada >> a[j];
        entrada >> bi;
        A_ineq.pb(a); b_ineq.pb(bi);

        for (int j = 0; j < m; ++j) a[j] = -a[j];
        A_ineq.pb(a); b_ineq.pb(-bi);
    }

    double val = solveLP();

    if (std::isnan(val)) saida << "inviavel" << endl;
    else if (val > INF/2) saida << "ilimitada" << endl;
    else {
        saida << "otima" << endl;
        saida << formatDouble(val) << endl;
    }

    entrada.close(); saida.close();

    return 0;
}