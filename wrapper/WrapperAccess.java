package wrapper;

public class WrapperAccess {

    // ===== Variables with different access modifiers =====

    public Integer publicVar = Integer.valueOf(10);      // public
    protected Integer protectedVar = Integer.valueOf(20); // protected
    Integer defaultVar = Integer.valueOf(30);             // default
    private Integer privateVar = Integer.valueOf(40);     // private

    // ===== Methods with different access modifiers =====

    public void showPublic() {
        System.out.println("Public Integer value: " + publicVar);
    }

    protected void showProtected() {
        System.out.println("Protected Integer value: " + protectedVar);
    }

    void showDefault() {
        System.out.println("Default Integer value: " + defaultVar);
    }

    private void showPrivate() {
        System.out.println("Private Integer value: " + privateVar);
    }

    // Public method accessing private method
    public void accessPrivate() {
        showPrivate();
    }
    public static void main(String[] args) {
         WrapperAccess obj = new WrapperAccess();

        obj.showPublic();       // ✔ public
        obj.showProtected();    // ✔ protected
        obj.showDefault();      // ✔ default
        // obj.showPrivate();   // private (not accessible)

        obj.accessPrivate();    // ✔ private accessed indirectly
    }
}
