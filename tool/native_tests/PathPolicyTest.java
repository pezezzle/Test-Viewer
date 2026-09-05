import com.pezezzle.testmasterviewer.PathPolicy;
public class PathPolicyTest {
    public static void main(String[] args) throws Exception {
        String[] valid = {"pcdrdata.sqlite3", "Prüfungen/pcdrdata.sqlite3", " Ordner\\db.sqlite "};
        String[] expected = {"pcdrdata.sqlite3", "Prüfungen/pcdrdata.sqlite3", "Ordner/db.sqlite"};
        for (int i=0; i<valid.length; i++) if (!expected[i].equals(PathPolicy.normalize(valid[i]))) throw new AssertionError("Path mismatch");
        String[] invalid = {"", "/db.sqlite", "../db", "x/../db", "x/./db", "x//db", "x/", "C:\\db", "x\0db", "a".repeat(501)};
        for (String path : invalid) { boolean rejected=false; try { PathPolicy.normalize(path); } catch (java.io.IOException ex) { rejected=true; } if (!rejected) throw new AssertionError("Path unexpectedly accepted"); }
        System.out.println("13 Java path validation cases passed");
    }
}
